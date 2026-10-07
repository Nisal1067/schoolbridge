import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AttachmentApiException implements Exception {
  final String message;
  AttachmentApiException(this.message);
  @override
  String toString() => message;
}

class ChatAttachmentApi {
  static const baseUrl = String.fromEnvironment(
    'CHAT_ATTACHMENT_API_URL',
    defaultValue: 'http://127.0.0.1:8081',
  );
  static const maxBytes = 10 * 1024 * 1024;
  static Uri endpoint(String chat, String message) {
    final base = Uri.parse(baseUrl);
    final local = ['localhost', '127.0.0.1', '10.0.2.2'].contains(base.host);
    if (base.scheme != 'https' && !(local && base.scheme == 'http')) {
      throw AttachmentApiException(
        'Attachment API must use HTTPS outside local development.',
      );
    }
    return base.replace(
      pathSegments: [
        ...base.pathSegments.where((s) => s.isNotEmpty),
        'chats',
        chat,
        'attachments',
        message,
      ],
    );
  }

  static Future<String> _token() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw AttachmentApiException('Sign in to access attachments.');
    }
    return token;
  }

  static void _check(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String message =
        'Attachment service unavailable. Check the server and your connection.';
    try {
      message =
          (jsonDecode(response.body) as Map)['error'] as String? ?? message;
    } catch (_) {
      /* Non-JSON server response. */
    }
    throw AttachmentApiException(message);
  }

  static Future<Map<String, dynamic>> upload(
    String chat,
    String message,
    String name,
    Uint8List bytes,
    void Function(double) onProgress,
  ) async {
    final client = http.Client();
    try {
      final request = _UploadRequest(endpoint(chat, message), onProgress)
        ..headers['Authorization'] = 'Bearer ${await _token()}'
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: name),
        );
      final response = await (() async {
        return http.Response.fromStream(await client.send(request));
      })().timeout(const Duration(seconds: 90));
      _check(response);
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    } finally {
      client.close();
    }
  }

  static Future<void> discard(String chat, String message) async {
    final client = http.Client();
    try {
      final response = await client
          .delete(
            endpoint(chat, message),
            headers: {'Authorization': 'Bearer ${await _token()}'},
          )
          .timeout(const Duration(seconds: 30));
      _check(response);
    } finally {
      client.close();
    }
  }

  static Future<Uint8List> download(Map<String, dynamic> attachment) async {
    final parts = (attachment['path'] as String).split('/');
    if (parts.length != 5 || parts[0] != 'chats' || parts[4] != 'attachment') {
      throw AttachmentApiException('Invalid attachment reference.');
    }
    final client = http.Client();
    try {
      final request = http.Request('GET', endpoint(parts[1], parts[3]))
        ..headers['Authorization'] = 'Bearer ${await _token()}';
      return await (() async {
        final response = await client.send(request);
        if (response.statusCode != 200) {
          _check(await http.Response.fromStream(response));
        }
        final bytes = BytesBuilder(copy: false);
        await for (final chunk in response.stream) {
          if (bytes.length + chunk.length > maxBytes) {
            throw AttachmentApiException('Attachment exceeds 10 MB.');
          }
          bytes.add(chunk);
        }
        return bytes.takeBytes();
      })().timeout(const Duration(seconds: 45));
    } finally {
      client.close();
    }
  }
}

class _UploadRequest extends http.MultipartRequest {
  final void Function(double) onProgress;
  _UploadRequest(Uri url, this.onProgress) : super('POST', url);
  @override
  http.ByteStream finalize() {
    final stream = super.finalize();
    final total = contentLength;
    int sent = 0;
    return http.ByteStream(
      stream.transform(
        StreamTransformer.fromHandlers(
          handleData: (data, sink) {
            sent += data.length;
            if (total > 0) onProgress(sent / total);
            sink.add(data);
          },
        ),
      ),
    );
  }
}
