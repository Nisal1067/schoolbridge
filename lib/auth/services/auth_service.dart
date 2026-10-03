import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_role.dart';

class AuthService {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> logout() => FirebaseAuth.instance.signOut();

  Future<UserRole> login(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw const AuthException('Enter your email and password.');
    }
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException('Unable to sign in. Please try again.');
      }
      // Read from the server so cached account permissions cannot grant access.
      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));
      final data = document.data();
      if (data == null) {
        throw const AuthException(
          'Your user profile is missing. Contact your school.',
        );
      }
      if (data['active'] != true) {
        throw const AuthException(
          'Your account is inactive. Contact your school.',
        );
      }
      for (final role in UserRole.values) {
        if (data['role'] == role.name) return role;
      }
      throw const AuthException(
        'Your account role is invalid. Contact your school.',
      );
    } catch (error) {
      // A Firebase session alone must not survive a failed profile check.
      try {
        await logout();
      } catch (_) {
        // Preserve the original login error when sign-out also fails.
      }
      if (error is AuthException) rethrow;
      if (error is FirebaseAuthException) {
        throw AuthException(switch (error.code) {
          'invalid-credential' ||
          'wrong-password' ||
          'user-not-found' ||
          'invalid-email' => 'Email or password is incorrect.',
          'user-disabled' => 'Your account is inactive. Contact your school.',
          'too-many-requests' => 'Too many attempts. Please try again later.',
          'network-request-failed' =>
            'Check your internet connection and try again.',
          _ => 'Unable to sign in. Please try again.',
        });
      }
      if (error is FirebaseException) {
        throw AuthException(switch (error.code) {
          'permission-denied' =>
            'Unable to access your profile. Contact your school.',
          'unavailable' || 'deadline-exceeded' =>
            'Check your internet connection and try again.',
          _ => 'Unable to load your profile. Please try again.',
        });
      }
      throw const AuthException('Unable to sign in. Please try again.');
    }
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}
