import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class ProfilePhotoException implements Exception {
  final String message;
  const ProfilePhotoException(this.message);

  @override
  String toString() => message;
}

class ProfilePhotoService {
  static const maxBytes = 3 * 1024 * 1024; // 3 MB

  static const _cloudName = 'mkbiqlpk';
  static const _apiKey = '435597969727599';
  static const _apiSecret = '3t7L-J8H-QyuYit8MExLS92W910';

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const ProfilePhotoException('Sign in to update your profile photo.');
    }

    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 88,
    );
    if (image == null) return;

    final fileName = image.name.contains('.') ? image.name : 'profile.jpg';
    final bytes = await image.readAsBytes();
    final error = validate(fileName, bytes.length);
    if (error != null) throw ProfilePhotoException(error);

    try {
      final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
      final publicId = 'schoolbridge/profile-photos/${user.uid}';
      
      // Compute Cloudinary signature
      final strToSign = 'public_id=$publicId&timestamp=$timestamp$_apiSecret';
      final bytesToSign = utf8.encode(strToSign);
      final signature = sha1.convert(bytesToSign).toString();

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['api_key'] = _apiKey
        ..fields['timestamp'] = timestamp
        ..fields['public_id'] = publicId
        ..fields['signature'] = signature
        ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

      final client = http.Client();
      final response = await http.Response.fromStream(
        await client.send(request).timeout(const Duration(seconds: 90))
      );
      client.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final url = decoded['secure_url'];

        // Update Firestore user profile
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'photoProvider': 'cloudinary',
          'photoUrl': url,
          'photoPublicId': publicId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        throw Exception('Cloudinary error: ${response.body}');
      }
    } on TimeoutException {
      throw const ProfilePhotoException('Upload timed out. Check your internet connection.');
    } catch (e) {
      throw ProfilePhotoException('Could not upload profile photo. Try again later.');
    }
  }

  static Future<Uint8List?> load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
      
      final url = doc.data()?['photoUrl'] as String?;
      if (url == null || url.isEmpty) return null;

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 45));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
