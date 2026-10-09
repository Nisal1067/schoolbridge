import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../user_communication/chat_attachment_api.dart';

class ProfilePhotoException implements Exception {
  final String message;
  const ProfilePhotoException(this.message);

  @override
  String toString() => message;
}

class ProfilePhotoService {
  static const maxBytes = 3 * 1024 * 1024;

  static Uri get _endpoint {
    final base = Uri.parse(ChatAttachmentApi.baseUrl);
    final local = ['localhost', '127.0.0.1', '10.0.2.2'].contains(base.host);
    if (base.scheme != 'https' && !(local && base.scheme == 'http')) {
      throw const ProfilePhotoException(
        'Profile photo API must use HTTPS outside local development.',
      );
    }
    return base.replace(
      pathSegments: [
        ...base.pathSegments.where((segment) => segment.isNotEmpty),
        'profile-photo',
      ],
    );
  }

  static Future<String> _token() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw const ProfilePhotoException('Sign in to update your profile photo.');
    }
    return token;
  }

  static String? validate(String name, int size) {
    final extension = name.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(extension)) {
      return 'Choose a JPG or PNG profile image.';
    }
    if (size <= 0) return 'Choose a non-empty image.';
    if (size > maxBytes) return 'Choose an image under 3 MB.';
    return null;
  }

  static Future<void> pickAndUpload() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 88,
    );
    if (image == null) return;

    final fileName = image.name.contains('.') ? image.name : 'profile.jpg';
    final bytes = await image.readAsBytes();
    final error = validate(fileName, bytes.length);
    if (error != null) throw ProfilePhotoException(error);

    final client = http.Client();
    try {
      final request = http.MultipartRequest('POST', _endpoint)
        ..headers['Authorization'] = 'Bearer ${await _token()}'
        ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: fileName),
        );
      final response = await http.Response.fromStream(
        await client.send(request).timeout(const Duration(seconds: 90)),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        var message =
            'Profile photo upload failed (${response.statusCode}). Restart attachment_backend.';
        try {
          message =
              (jsonDecode(response.body) as Map)['error'] as String? ??
              message;
        } catch (_) {
          // Non-JSON server response.
        }
        throw ProfilePhotoException(message);
      }
    } on TimeoutException {
      throw const ProfilePhotoException(
        'Profile photo server is not responding. Check attachment_backend.',
      );
    } on http.ClientException {
      throw const ProfilePhotoException(
        'Profile photo server is not reachable. Start attachment_backend and try again.',
      );
    } finally {
      client.close();
    }
  }

  static Future<Uint8List?> load() async {
    final client = http.Client();
    try {
      final response = await client
          .get(_endpoint, headers: {'Authorization': 'Bearer ${await _token()}'})
          .timeout(const Duration(seconds: 45));
      if (response.statusCode == 404) return null;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const ProfilePhotoException('Could not load profile photo.');
      }
      return response.bodyBytes;
    } finally {
      client.close();
    }
  }
}
