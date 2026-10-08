import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:schoolbridge/core/config/file_storage_config.dart';
import 'package:schoolbridge/features/homework_announcements/models/attachment.dart';
import 'package:schoolbridge/features/homework_announcements/services/attachment_service.dart';

const _config = FileStorageConfig(url: 'https://abc.supabase.co/');
const _function = 'https://abc.supabase.co/functions/v1/homework-files';
const _signedUpload =
    'https://abc.supabase.co/storage/v1/object/upload/sign/homework-files/x?token=t';

final _pdf = PickedAttachment(
  name: 'my work.pdf',
  bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]),
  contentType: kPdfType,
);

FileStorageApi _api(
  MockClient client, {
  IdTokenProvider? idToken,
  FileStorageConfig config = _config,
}) => FileStorageApi(
  client: client,
  config: config,
  idToken: idToken ?? (force) async => 'firebase-token',
);

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

void main() {
  group('FileStorageConfig', () {
    test('placeholder means not configured', () {
      const placeholder = FileStorageConfig(
        url: 'https://YOUR-PROJECT-REF.supabase.co',
      );
      expect(placeholder.isConfigured, isFalse);
      expect(_config.isConfigured, isTrue);
    });

    test('points at the Edge Function without a double slash', () {
      expect(_config.endpoint.toString(), _function);
    });
  });

  group('AttachmentUploader', () {
    test(
      'asks the function first, then uploads to the signed address',
      () async {
        final functionCalls = <http.Request>[];
        late http.Request put;
        final client = MockClient((request) async {
          if (request.url.toString() == _function) {
            functionCalls.add(request);
            return _json({
              'path': 'homework_attachments/s1/t1/h1/1_my_work.pdf',
              'signedUrl': _signedUpload,
              'headers': {'apikey': 'public-anon'},
            });
          }
          put = request;
          return http.Response('{}', 200);
        });
        final uploader = AttachmentUploader(api: _api(client));

        final result = await uploader.uploadAll(
          folder: 'homework_attachments/s1/t1/h1',
          files: [_pdf],
        );

        expect(result, hasLength(1));
        expect(
          result.first.path,
          'homework_attachments/s1/t1/h1/1_my_work.pdf',
        );
        expect(result.first.url, isEmpty);
        expect(result.first.name, 'my work.pdf');

        final ask = functionCalls.single;
        expect(ask.headers['Authorization'], 'Bearer firebase-token');
        expect(ask.headers.containsKey('apikey'), isFalse);
        final body = jsonDecode(ask.body) as Map<String, dynamic>;
        expect(body['action'], 'upload');
        expect(body['folder'], 'homework_attachments/s1/t1/h1');
        expect(body['contentType'], kPdfType);
        expect(body['size'], 5);

        expect(put.method, 'PUT');
        expect(put.url.toString(), _signedUpload);
        expect(put.headers['apikey'], 'public-anon');
        expect(put.headers['Content-Type'], kPdfType);
        expect(put.bodyBytes, _pdf.bytes);
      },
    );

    test('shows the server message when it refuses, and cleans up', () async {
      final actions = <String>[];
      var grants = 0;
      final client = MockClient((request) async {
        if (request.url.toString() != _function) {
          return http.Response('{}', 200);
        }
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        actions.add(body['action'] as String);
        if (body['action'] == 'upload') {
          grants++;
          if (grants == 2) {
            return _json({
              'error': 'You are not allowed to upload files here.',
            }, 403);
          }
          return _json({
            'path': 'homework_attachments/s/t/h/1_a.pdf',
            'signedUrl': _signedUpload,
          });
        }
        return _json({'deleted': <String>[], 'denied': <String>[]});
      });
      final uploader = AttachmentUploader(api: _api(client));

      await expectLater(
        uploader.uploadAll(
          folder: 'homework_attachments/s/t/h',
          files: [_pdf, _pdf],
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('not allowed'),
          ),
        ),
      );
      // first file uploaded, second refused, first one removed again
      expect(actions, ['upload', 'upload', 'delete']);
    });

    test('says storage is not set up when the function is missing', () async {
      final client = MockClient(
        (request) async => http.Response('Not found', 404),
      );
      final uploader = AttachmentUploader(api: _api(client));
      await expectLater(
        uploader.uploadAll(folder: 'f', files: [_pdf]),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('not set up'),
          ),
        ),
      );
    });

    test('homework without files never needs storage', () async {
      const placeholder = FileStorageConfig(
        url: 'https://YOUR-PROJECT-REF.supabase.co',
      );
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        return http.Response('{}', 200);
      });
      final uploader = AttachmentUploader(
        api: _api(client, config: placeholder),
      );
      expect(await uploader.uploadAll(folder: 'f', files: const []), isEmpty);
      await uploader.deleteAll(const []);
      expect(calls, 0);
    });

    test('deleteAll sends the paths and ignores failures', () async {
      late Map<String, dynamic> sent;
      final client = MockClient((request) async {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        throw http.ClientException('offline');
      });
      final uploader = AttachmentUploader(api: _api(client));
      const file = Attachment(
        name: 'a.png',
        path: 'homework_submissions/s/h/u/1_a.png',
        contentType: kPngType,
        size: 1,
      );

      await uploader.deleteAll([file]);

      expect(sent['action'], 'delete');
      expect(sent['paths'], ['homework_submissions/s/h/u/1_a.png']);
    });
  });

  group('FileStorageApi', () {
    test(
      'retries once with a fresh token when the first one is rejected',
      () async {
        final seen = <String?>[];
        final client = MockClient((request) async {
          seen.add(request.headers['Authorization']);
          return request.headers['Authorization'] == 'Bearer old'
              ? _json({'error': 'expired'}, 401)
              : _json({'ok': true});
        });
        final api = _api(
          client,
          idToken: (force) async => force ? 'new' : 'old',
        );

        final result = await api.call({
          'action': 'sign',
          'paths': ['p'],
        });

        expect(result['ok'], isTrue);
        expect(seen, ['Bearer old', 'Bearer new']);
      },
    );

    test('refuses to call without a signed-in user', () async {
      final client = MockClient((request) async => http.Response('{}', 200));
      final api = _api(client, idToken: (force) async => null);
      await expectLater(
        api.call({'action': 'sign'}),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('AttachmentUrls', () {
    const photo = Attachment(
      name: 'a.png',
      path: 'homework_attachments/s/t/h/1_a.png',
      contentType: kPngType,
      size: 1,
    );
    const note = Attachment(
      name: 'b.png',
      path: 'homework_attachments/s/t/h/2_b.png',
      contentType: kPngType,
      size: 1,
    );

    test('sends nearby requests as one call, caches, and returns null when refused', () async {
      final requests = <List<dynamic>>[];
      final client = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        requests.add(body['paths'] as List<dynamic>);
        return _json({
          'urls': {photo.path: 'https://signed.example/a?token=1'},
          'expiresIn': 900,
        });
      });
      final urls = AttachmentUrls(api: _api(client));

      final results = await Future.wait([
        urls.urlFor(photo),
        urls.urlFor(note),
      ]);

      expect(results[0], 'https://signed.example/a?token=1');
      expect(results[1], isNull); // the server left it out: not allowed
      expect(requests, hasLength(1));
      expect(requests.single, containsAll([photo.path, note.path]));

      // cached: no second request
      expect(await urls.urlFor(photo), 'https://signed.example/a?token=1');
      expect(requests, hasLength(1));
    });

    test('files from the earlier public version keep their own link', () async {
      final client = MockClient((request) async => http.Response('{}', 500));
      final urls = AttachmentUrls(api: _api(client));
      const old = Attachment(
        name: 'old.pdf',
        url: 'https://old.example/old.pdf',
        path: '',
        contentType: kPdfType,
        size: 1,
      );
      expect(await urls.urlFor(old), 'https://old.example/old.pdf');
    });
  });
}
