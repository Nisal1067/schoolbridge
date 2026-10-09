import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class AttachmentApiException implements Exception {
  final String message;
  AttachmentApiException(this.message);
  @override
  String toString() => message;
}

class ChatAttachmentApi {
  static const maxBytes = 10 * 1024 * 1024;
  
  static const _cloudName = 'mkbiqlpk';
  static const _apiKey = '435597969727599';
  static const _apiSecret = '3t7L-J8H-QyuYit8MExLS92W910';

  static String _getContentType(String name) {
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'png': return 'image/png';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'pdf': return 'application/pdf';
      case 'txt': return 'text/plain';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default: return 'application/octet-stream';
    }
  }

  static Future<Map<String, dynamic>> upload(
    String chat,
    String messageId,
    String name,
    Uint8List bytes,
    void Function(double) onProgress,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw AttachmentApiException('Sign in to access attachments.');
    }
    if (bytes.length > maxBytes) {
      throw AttachmentApiException('Attachment exceeds 10 MB.');
    }

    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final publicId = 'schoolbridge/chats/$chat/${user.uid}/$messageId/$name';
    final contentType = _getContentType(name);

    final strToSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
    final bytesToSign = utf8.encode(strToSign);
    final signature = sha1.convert(bytesToSign).toString();

    final resourceType = contentType.startsWith('image/') ? 'image' : 'raw';
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload');

    final request = _UploadRequest(uri, onProgress)
      ..fields['api_key'] = _apiKey
      ..fields['timestamp'] = timestamp
      ..fields['public_id'] = publicId
      ..fields['signature'] = signature
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: name));

    final client = http.Client();
    try {
      final response = await (() async {
        return http.Response.fromStream(await client.send(request));
      })().timeout(const Duration(seconds: 90));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        return {
          'provider': 'cloudinary',
          'path': publicId,
          'name': name,
          'size': bytes.length,
          'contentType': contentType,
          'url': decoded['secure_url'],
        };
      } else {
        throw AttachmentApiException('Attachment upload failed: ${response.statusCode}');
      }
    } catch (e) {
      throw AttachmentApiException('Upload failed: $e');
    } finally {
      client.close();
    }
  }

  static Future<void> discard(String chat, String messageId) async {
    // Cloudinary drafts can be ignored, or deleted using Destroy API. 
    // Usually discarded natively if we just don't persist them in firestore.
  }

  static Future<Uint8List> download(Map<String, dynamic> attachment) async {
    try {
      final url = attachment['url'] as String?;
      if (url == null) {
        throw AttachmentApiException('Attachment not found.');
      }
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 45));
      if (response.statusCode != 200) {
        throw AttachmentApiException('Attachment could not be downloaded.');
      }
      return response.bodyBytes;
    } catch (e) {
      throw AttachmentApiException('Download failed: $e');
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
