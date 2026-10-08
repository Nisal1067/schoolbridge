import 'dart:async';
import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../core/config/file_storage_config.dart';
import '../models/attachment.dart';

/// Where a file is chosen from.
enum AttachmentSource { camera, gallery, files }

/// What the user picked, plus a message for every file that was turned away.
class PickOutcome {
  final List<PickedAttachment> files;
  final List<String> problems;

  const PickOutcome(this.files, this.problems);
}

/// Opens the system pickers and checks the chosen files (size and real type).
class AttachmentPicker {
  static const XTypeGroup _documents = XTypeGroup(
    label: 'PDF or image',
    extensions: <String>['pdf', 'jpg', 'jpeg', 'png'],
    mimeTypes: <String>['application/pdf', 'image/jpeg', 'image/png'],
    uniformTypeIdentifiers: <String>[
      'com.adobe.pdf',
      'public.jpeg',
      'public.png',
    ],
  );

  /// Camera and gallery are offered on phones. Web and desktop go straight to
  /// the file dialog, which already lists images.
  static bool get hasPhotoSources =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<PickOutcome> pick(
    AttachmentSource source, {
    required int maxFiles,
  }) async {
    List<XFile> chosen = const [];
    try {
      switch (source) {
        case AttachmentSource.camera:
          final photo = await ImagePicker().pickImage(
            source: ImageSource.camera,
            maxWidth: 2400,
            maxHeight: 2400,
            imageQuality: 85,
          );
          if (photo != null) chosen = [photo];
        case AttachmentSource.gallery:
          chosen = await ImagePicker().pickMultiImage(
            maxWidth: 2400,
            maxHeight: 2400,
            imageQuality: 85,
          );
        case AttachmentSource.files:
          chosen = await openFiles(acceptedTypeGroups: const [_documents]);
      }
    } catch (_) {
      return const PickOutcome([], [
        'Could not open the file picker. Check the app permissions.',
      ]);
    }

    final files = <PickedAttachment>[];
    final problems = <String>[];
    for (final item in chosen) {
      if (files.length >= maxFiles) {
        problems.add('You can attach up to $kMaxAttachments files.');
        break;
      }
      final label = item.name.isEmpty ? 'This file' : item.name;
      try {
        if (await item.length() > kMaxAttachmentBytes) {
          problems.add('$label is larger than 10 MB.');
          continue;
        }
        final bytes = await item.readAsBytes();
        final type = sniffContentType(bytes);
        if (type == null) {
          problems.add('$label is not a PDF, JPG or PNG file.');
          continue;
        }
        files.add(
          PickedAttachment(
            name: nameWithExtension(
              item.name.isEmpty ? 'file' : item.name,
              type,
            ),
            bytes: bytes,
            contentType: type,
          ),
        );
      } catch (_) {
        problems.add('Could not read $label.');
      }
    }
    return PickOutcome(files, problems);
  }
}

/// The secure function answered with an error status.
class StorageFailure implements Exception {
  final int statusCode;

  /// A plain-language message written by the function, when there is one.
  final String? message;

  const StorageFailure(this.statusCode, [this.message]);
}

/// Gives the current Firebase ID token. [forceRefresh] asks for a new one.
typedef IdTokenProvider = Future<String?> Function(bool forceRefresh);

Future<String?> _firebaseIdToken(bool forceRefresh) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  return user.getIdToken(forceRefresh);
}

/// Talks to the "homework-files" Edge Function.
///
/// Every call carries the signed-in user's Firebase ID token. The function
/// verifies it, checks the user's role and ownership in Firestore and only
/// then answers. This app holds no Supabase key at all.
class FileStorageApi {
  final http.Client? _clientOverride;
  final FileStorageConfig _config;
  final IdTokenProvider _idToken;

  FileStorageApi({
    http.Client? client,
    this._config = FileStorageConfig.current,
    IdTokenProvider? idToken,
  }) : _clientOverride = client,
       _idToken = idToken ?? _firebaseIdToken;

  /// Sends one action to the function and returns its JSON answer.
  Future<Map<String, dynamic>> call(Map<String, dynamic> body) async {
    if (!_config.isConfigured) {
      throw StateError(
        'File storage is not set up yet. Please contact your school.',
      );
    }
    final client = _clientOverride ?? http.Client();
    try {
      var token = await _idToken(false);
      if (token == null) throw StateError('Please sign in again.');
      var response = await _post(client, token, body);
      if (response.statusCode == 401) {
        // The token may have just expired: get a fresh one and try once more.
        token = await _idToken(true);
        if (token == null) throw StateError('Please sign in again.');
        response = await _post(client, token, body);
      }

      Object? decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
      final json = decoded is Map<String, dynamic> ? decoded : null;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = json?['error'];
        throw StorageFailure(
          response.statusCode,
          message is String ? message : null,
        );
      }
      return json ?? const {};
    } finally {
      if (_clientOverride == null) client.close();
    }
  }

  Future<http.Response> _post(
    http.Client client,
    String token,
    Map<String, dynamic> body,
  ) {
    return client
        .post(
          _config.endpoint,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));
  }

  /// Sends the file's bytes to the one-time signed upload address that the
  /// function handed out for exactly one path.
  Future<void> putFile(
    String signedUrl, {
    required Uint8List bytes,
    required String contentType,
    Map<String, String> headers = const {},
  }) async {
    final client = _clientOverride ?? http.Client();
    try {
      final response = await client
          .put(
            Uri.parse(signedUrl),
            headers: {
              ...headers,
              'Content-Type': contentType,
              'x-upsert': 'false',
              'cache-control': 'max-age=3600',
            },
            body: bytes,
          )
          .timeout(const Duration(seconds: 90));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StorageFailure(response.statusCode);
      }
    } finally {
      if (_clientOverride == null) client.close();
    }
  }
}

/// Uploads files to private storage and deletes them again.
///
/// All permission checks happen in the Edge Function, not here: a teacher can
/// only write into their own homework's folder, a student only into their own
/// submission's folder, and nobody else's files can be deleted.
class AttachmentUploader {
  final FileStorageApi? _apiOverride;
  FileStorageApi? _api;

  AttachmentUploader({FileStorageApi? api}) : _apiOverride = api;

  // Created on first use, so building a service never touches Firebase.
  FileStorageApi get _client => _api ??= _apiOverride ?? FileStorageApi();

  /// Teacher reference files: homework_attachments/{school}/{teacher}/{homework}
  static String homeworkFolder({
    required String schoolId,
    required String teacherId,
    required String homeworkId,
  }) => 'homework_attachments/$schoolId/$teacherId/$homeworkId';

  /// Student files: homework_submissions/{school}/{homework}/{student}
  static String submissionFolder({
    required String schoolId,
    required String homeworkId,
    required String studentId,
  }) => 'homework_submissions/$schoolId/$homeworkId/$studentId';

  /// Uploads every file. If one fails, the ones already uploaded are removed
  /// and a [StateError] with a readable message is thrown.
  Future<List<Attachment>> uploadAll({
    required String folder,
    required List<PickedAttachment> files,
  }) async {
    if (files.isEmpty) return const [];
    final done = <Attachment>[];
    try {
      for (final file in files) {
        done.add(await _upload(folder, file));
      }
    } catch (e) {
      await deleteAll(done);
      throw _friendly(e);
    }
    return done;
  }

  Future<Attachment> _upload(String folder, PickedAttachment file) async {
    // 1. Ask the function for permission. It answers with a one-time upload
    //    address for a path it chose itself.
    final grant = await _client.call({
      'action': 'upload',
      'folder': folder,
      'fileName': file.name,
      'contentType': file.contentType,
      'size': file.size,
    });
    final path = grant['path'];
    final signedUrl = grant['signedUrl'];
    if (path is! String || signedUrl is! String) {
      throw const StorageFailure(502);
    }
    final extra = grant['headers'];
    // 2. Send the bytes to that address.
    await _client.putFile(
      signedUrl,
      bytes: file.bytes,
      contentType: file.contentType,
      headers: extra is Map
          ? {for (final e in extra.entries) '${e.key}': '${e.value}'}
          : const {},
    );
    return Attachment(
      name: file.name,
      path: path,
      contentType: file.contentType,
      size: file.size,
    );
  }

  /// Best effort: a file that cannot be deleted is left behind, which is
  /// harmless, so errors are ignored.
  Future<void> deleteAll(Iterable<Attachment> files) async {
    final paths = [
      for (final file in files)
        if (file.path.isNotEmpty) file.path,
    ];
    for (var start = 0; start < paths.length; start += 20) {
      try {
        await _client.call({
          'action': 'delete',
          'paths': paths.skip(start).take(20).toList(),
        });
      } catch (_) {
        // Ignored on purpose, see above.
      }
    }
  }

  Object _friendly(Object error) {
    if (error is StateError) return error;
    if (error is StorageFailure) {
      final code = error.statusCode;
      final message = error.message;
      if (code == 401) {
        return StateError('Your session has expired. Please sign in again.');
      }
      if (message != null &&
          (code == 400 || code == 403 || code == 413 || code == 429)) {
        return StateError(message);
      }
      if (code == 404) {
        return StateError(
          'File storage is not set up yet. Please contact your school.',
        );
      }
      if (code == 413 || code == 415) {
        return StateError(
          'This file is too large or is not a PDF, JPG or PNG.',
        );
      }
      if (code >= 500) {
        return StateError(
          'File storage is not available right now. Please try again later.',
        );
      }
    }
    if (error is TimeoutException) {
      return StateError(
        'The upload took too long. Check your connection and try again.',
      );
    }
    return StateError('Could not upload your files. Please try again.');
  }
}

class _SignedUrl {
  final String url;
  final DateTime goodUntil;
  const _SignedUrl(this.url, this.goodUntil);
}

/// Short-lived viewing links for files in the private bucket.
///
/// Links are requested from the function (which checks that the signed-in user
/// may see the file), kept in memory until shortly before they expire, and
/// requests made at about the same time are sent as one call.
class AttachmentUrls {
  /// Shared by the whole app.
  static final AttachmentUrls instance = AttachmentUrls();

  final FileStorageApi? _apiOverride;
  FileStorageApi? _api;
  final Map<String, _SignedUrl> _cache = {};
  final Map<String, Completer<String?>> _waiting = {};
  Timer? _flushTimer;

  AttachmentUrls({FileStorageApi? api}) : _apiOverride = api;

  FileStorageApi get _client => _api ??= _apiOverride ?? FileStorageApi();

  /// A link that opens [file], or null if the user may not see it. Throws if
  /// the storage cannot be reached.
  Future<String?> urlFor(Attachment file) {
    if (file.path.isEmpty) {
      // Written by an earlier public version: it already has its own link.
      return Future.value(file.url.isEmpty ? null : file.url);
    }
    final cached = _cache[file.path];
    if (cached != null && cached.goodUntil.isAfter(DateTime.now())) {
      return Future.value(cached.url);
    }
    final existing = _waiting[file.path];
    if (existing != null) return existing.future;
    final completer = Completer<String?>();
    _waiting[file.path] = completer;
    _flushTimer ??= Timer(const Duration(milliseconds: 30), _flush);
    return completer.future;
  }

  Future<void> _flush() async {
    final batch = Map<String, Completer<String?>>.of(_waiting);
    _waiting.clear();
    _flushTimer = null;
    final paths = batch.keys.toList();
    for (var start = 0; start < paths.length; start += 20) {
      final chunk = paths.skip(start).take(20).toList();
      try {
        final result = await _client.call({'action': 'sign', 'paths': chunk});
        final urls = result['urls'];
        final seconds = (result['expiresIn'] as num?)?.toInt() ?? 900;
        // Treated as expired a little early, so a link is never used on the
        // very last second.
        final goodUntil = DateTime.now().add(
          Duration(seconds: seconds > 90 ? seconds - 60 : 0),
        );
        for (final path in chunk) {
          final url = urls is Map ? urls[path] : null;
          if (url is String) {
            _cache[path] = _SignedUrl(url, goodUntil);
            batch[path]!.complete(url);
          } else {
            batch[path]!.complete(null);
          }
        }
      } catch (e) {
        for (final path in chunk) {
          batch[path]!.completeError(e);
        }
      }
    }
  }

  /// Forgets every link, for example when someone signs out.
  void clear() => _cache.clear();
}
