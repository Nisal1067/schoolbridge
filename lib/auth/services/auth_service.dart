import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/user_role.dart';

class AuthService {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> logout() => FirebaseAuth.instance.signOut();

  /// Looks up user profile in Firestore across `users` and `students` collections.
  Future<Map<String, dynamic>?> _findUserProfile({
    required String uid,
    required String email,
  }) async {
    final cleanEmail = email.trim();
    final lowerEmail = cleanEmail.toLowerCase();

    // 1. Try users collection by UID
    if (uid.isNotEmpty) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists && doc.data() != null) {
          return doc.data();
        }
      } catch (_) {}
    }

    // 2. Try users collection by lowercase email
    if (lowerEmail.isNotEmpty) {
      try {
        final q = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: lowerEmail)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) {
          return q.docs.first.data();
        }
      } catch (_) {}
    }

    // 3. Try users collection by exact email
    if (cleanEmail.isNotEmpty) {
      try {
        final q = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: cleanEmail)
            .limit(1)
            .get();
        if (q.docs.isNotEmpty) {
          return q.docs.first.data();
        }
      } catch (_) {}
    }

    // 4. Try students collection by UID
    if (uid.isNotEmpty) {
      try {
        final sDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(uid)
            .get();
        if (sDoc.exists && sDoc.data() != null) {
          final d = Map<String, dynamic>.from(sDoc.data()!);
          d['role'] = 'student';
          return d;
        }
      } catch (_) {}
    }

    // 5. Try students collection by email
    if (lowerEmail.isNotEmpty) {
      try {
        final sQuery = await FirebaseFirestore.instance
            .collection('students')
            .where('email', isEqualTo: lowerEmail)
            .limit(1)
            .get();
        if (sQuery.docs.isNotEmpty) {
          final d = Map<String, dynamic>.from(sQuery.docs.first.data());
          d['role'] = 'student';
          return d;
        }
      } catch (_) {}
    }

    // 6. Fallback scan on users collection for case-insensitive match
    try {
      final allUsers = await FirebaseFirestore.instance
          .collection('users')
          .get();
      for (final doc in allUsers.docs) {
        final d = doc.data();
        final docEmail = (d['email'] ?? '').toString().trim().toLowerCase();
        if (docEmail.isNotEmpty && (docEmail == lowerEmail || docEmail == cleanEmail)) {
          return d;
        }
      }
    } catch (_) {}

    // 7. Fallback scan on students collection
    try {
      final allStudents = await FirebaseFirestore.instance
          .collection('students')
          .get();
      for (final doc in allStudents.docs) {
        final d = Map<String, dynamic>.from(doc.data());
        final docEmail = (d['email'] ?? '').toString().trim().toLowerCase();
        if (docEmail.isNotEmpty && (docEmail == lowerEmail || docEmail == cleanEmail)) {
          d['role'] = 'student';
          return d;
        }
      }
    } catch (_) {}

    return null;
  }

  Future<UserRole> login(
    String email,
    String password, {
    UserRole? selectedRole,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || password.isEmpty) {
      throw const AuthException('Enter your email and password.');
    }

    try {
      User? user;
      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: cleanEmail,
          password: password,
        );
        user = credential.user;
      } on FirebaseAuthException catch (authErr) {
        // If user is not yet created in Firebase Auth (e.g. added via Web User Management),
        // but already exists in Firestore database, register in Firebase Auth with the password
        if (authErr.code == 'user-not-found' || authErr.code == 'invalid-credential') {
          final existingProfile = await _findUserProfile(uid: '', email: cleanEmail);
          if (existingProfile != null) {
            try {
              final newCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                email: cleanEmail,
                password: password,
              );
              user = newCred.user;
            } catch (_) {
              rethrow;
            }
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      if (user == null) {
        throw const AuthException('Unable to sign in. Please try again.');
      }

      // Read profile from Firestore
      Map<String, dynamic>? data = await _findUserProfile(
        uid: user.uid,
        email: user.email ?? cleanEmail,
      );

      // If profile is missing in Firestore, auto-create it using selected role
      if (data == null) {
        final assignedRole = selectedRole?.name ?? 'teacher';
        data = {
          'name': user.displayName ?? cleanEmail.split('@').first,
          'email': user.email ?? cleanEmail,
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
      } else {
        // Ensure users/{user.uid} document is present for services querying by UID
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

      // Resolve the database role
      final rawRole = (data['role'] ?? '').toString().trim().toLowerCase();
      UserRole dbRole;
      if (rawRole == 'admin' || rawRole == 'staff' || rawRole == 'administrator') {
        dbRole = UserRole.admin;
      } else if (rawRole == 'student') {
        dbRole = UserRole.student;
      } else if (rawRole == 'parent' || rawRole == 'guardian') {
        dbRole = UserRole.parent;
      } else if (rawRole == 'teacher' || rawRole == 'faculty') {
        dbRole = UserRole.teacher;
      } else {
        dbRole = selectedRole ?? UserRole.admin;
      }

      // Verify that the UI selectedRole matches the DB role
      if (selectedRole != null && selectedRole != dbRole) {
        throw RoleMismatchException(
          actualRole: dbRole,
          selectedRole: selectedRole,
        );
      }

      return dbRole;
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

class RoleMismatchException extends AuthException {
  final UserRole actualRole;
  final UserRole selectedRole;

  RoleMismatchException({
    required this.actualRole,
    required this.selectedRole,
  }) : super(
         'Role mismatch: This account is registered as ${actualRole.displayName}, not ${selectedRole.displayName}. Please select "${actualRole.displayName}" to log in.',
       );
}
