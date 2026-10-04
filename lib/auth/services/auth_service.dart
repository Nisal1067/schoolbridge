import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_role.dart';

class AuthService {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> logout() => FirebaseAuth.instance.signOut();

  Future<UserRole> login(
    String email,
    String password, {
    UserRole? selectedRole,
  }) async {
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

      // Read profile from Firestore users collection
      Map<String, dynamic>? data;
      try {
        final document = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        data = document.data();
      } catch (_) {}

      // Fallback: look up profile by email (case-insensitive)
      if (data == null && user.email != null) {
        try {
          final query = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: user.email!.trim().toLowerCase())
              .limit(1)
              .get();
          if (query.docs.isNotEmpty) {
            data = query.docs.first.data();
          } else {
            // Also try with original case
            final queryOrig = await FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: user.email!.trim())
                .limit(1)
                .get();
            if (queryOrig.docs.isNotEmpty) {
              data = queryOrig.docs.first.data();
            }
          }
        } catch (_) {}
      }

      // Fallback: look up in students collection
      if (data == null) {
        try {
          final sDoc = await FirebaseFirestore.instance
              .collection('students')
              .doc(user.uid)
              .get();
          if (sDoc.exists) {
            data = sDoc.data();
            data?['role'] = 'student';
          }
        } catch (_) {}
      }

      // If profile is still missing in Firestore, auto-create it using selected role
      if (data == null) {
        final assignedRole = selectedRole?.name ?? 'teacher';
        data = {
          'name': user.displayName ?? email.split('@').first,
          'email': user.email ?? email.trim(),
          'role': assignedRole,
          'active': true,
          'status': 'Active',
          'schoolId': 'school01',
          'createdAt': FieldValue.serverTimestamp(),
        };
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(data, SetOptions(merge: true));
        } catch (_) {}
      }

      if (data['active'] == false || data['status'] == 'Inactive') {
        throw const AuthException(
          'Your account is inactive. Contact your school.',
        );
      }

      if (selectedRole != null) {
        return selectedRole;
      }

      final rawRole = (data['role'] ?? 'teacher')
          .toString()
          .trim()
          .toLowerCase();

      // Resolve roles (including staff -> teacher)
      if (rawRole == 'admin') {
        return UserRole.admin;
      } else if (rawRole == 'student') {
        return UserRole.student;
      } else if (rawRole == 'parent') {
        return UserRole.parent;
      } else {
        // 'teacher', 'staff', 'faculty' all map to teacher
        return UserRole.teacher;
      }
    } catch (error) {
      // A Firebase session alone must not survive a failed profile check.
      try {
        await logout();
      } catch (_) {
        // Preserve the original login error when sign-out also fails.
      }
      if (error is AuthException) rethrow;
      if (error is FirebaseAuthException) {
        // ignore: avoid_print
        print('FirebaseAuthException [${error.code}]: ${error.message}');
        throw AuthException(switch (error.code) {
          'operation-not-allowed' =>
            'Email/Password sign-in is disabled in Firebase Console (Authentication > Sign-in method).',
          'invalid-credential' ||
          'wrong-password' ||
          'user-not-found' ||
          'invalid-email' =>
            'Email or password is incorrect (${error.code}). Check Firebase Authentication > Users.',
          'user-disabled' => 'Your account is inactive. Contact your school.',
          'too-many-requests' => 'Too many attempts. Please try again later.',
          'network-request-failed' =>
            'Check your internet connection and try again.',
          _ => error.message ?? 'Unable to sign in. Please try again.',
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
