import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../firebase_options.dart';
import '../models/user_item.dart';
import 'class_assignment_service.dart';

class UserManagementService {
  static final UserManagementService _instance =
      UserManagementService._internal();
  factory UserManagementService() => _instance;

  UserManagementService._internal() {
    _initFirestoreListener();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<UserItem> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  final StreamController<List<UserItem>> _streamController =
      StreamController<List<UserItem>>.broadcast();

  Stream<List<UserItem>> get usersStream => _streamController.stream;

  List<UserItem> get currentUsers => List.unmodifiable(_users);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _initFirestoreListener() {
    try {
      _firestore
          .collection('users')
          .snapshots()
          .listen(
            (snapshot) async {
              _errorMessage = null;
              final List<UserItem> realUsers = [];

              for (final doc in snapshot.docs) {
                final data = doc.data();
                realUsers.add(UserItem.fromMap(data, doc.id));
              }

              // Check if students are also stored in students collection
              try {
                final studentSnap = await _firestore
                    .collection('students')
                    .get();
                for (final sDoc in studentSnap.docs) {
                  final sData = sDoc.data();
                  final sName = sData['name'] ?? '';
                  final alreadyAdded = realUsers.any(
                    (u) =>
                        u.id == sDoc.id ||
                        (u.name.isNotEmpty && u.name == sName),
                  );

                  if (!alreadyAdded) {
                    realUsers.add(
                      UserItem(
                        id: sDoc.id,
                        name: sName,
                        email: sData['email'] ?? '',
                        phone: sData['phone'] ?? '',
                        role: 'Student',
                        gradeOrClass: sData['classId'] ?? sData['grade'] ?? '',
                        status: sData['active'] == false
                            ? 'Inactive'
                            : 'Active',
                        joinedDate: sData['joinedDate'] ?? 'Jan 15, 2026',
                      ),
                    );
                  }
                }
              } catch (_) {}

              _users = realUsers;
              _isLoading = false;
              _streamController.add(List.unmodifiable(_users));
            },
            onError: (err) {
              _errorMessage = err.toString();
              _isLoading = false;
              _streamController.add(List.unmodifiable(_users));
            },
          );
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }
  }

  Future<List<UserItem>> fetchUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final List<UserItem> realUsers = snapshot.docs.map((doc) {
        return UserItem.fromMap(doc.data(), doc.id);
      }).toList();

      try {
        final studentSnap = await _firestore.collection('students').get();
        for (final sDoc in studentSnap.docs) {
          final sData = sDoc.data();
          final sName = sData['name'] ?? '';
          if (!realUsers.any((u) => u.id == sDoc.id || u.name == sName)) {
            realUsers.add(
              UserItem(
                id: sDoc.id,
                name: sName,
                email: sData['email'] ?? '',
                phone: sData['phone'] ?? '',
                role: 'Student',
                gradeOrClass: sData['classId'] ?? sData['grade'] ?? '',
                status: sData['active'] == false ? 'Inactive' : 'Active',
                joinedDate: sData['joinedDate'] ?? 'Jan 15, 2026',
              ),
            );
          }
        }
      } catch (_) {}

      _users = realUsers;
      _isLoading = false;
      _streamController.add(List.unmodifiable(_users));
    } catch (_) {
      _isLoading = false;
    }
    return currentUsers;
  }

  /// Generates a secure, readable temporary password
  static String generateSecurePassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    final rand = Random();
    final letter1 = chars[rand.nextInt(chars.length)];
    final letter2 = chars[rand.nextInt(chars.length)].toLowerCase();
    final num = 1000 + rand.nextInt(9000);
    return 'Sb@$num$letter1$letter2';
  }

  /// Generates a guaranteed unique admission number in format STU-YYYY-XXXX
  Future<String> generateUniqueAdmissionNo() async {
    final currentYear = DateTime.now().year;
    final existingNumbers = <String>{};

    try {
      final userSnap = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();
      for (final doc in userSnap.docs) {
        final adm = doc.data()['admissionNo']?.toString().trim();
        if (adm != null && adm.isNotEmpty) {
          existingNumbers.add(adm.toUpperCase());
        }
      }
    } catch (_) {}

    try {
      final studentSnap = await _firestore.collection('students').get();
      for (final doc in studentSnap.docs) {
        final adm = (doc.data()['admissionNo'] ?? doc.data()['indexNo'])
            ?.toString()
            .trim();
        if (adm != null && adm.isNotEmpty) {
          existingNumbers.add(adm.toUpperCase());
        }
      }
    } catch (_) {}

    for (final u in _users) {
      if (u.admissionNo.isNotEmpty) {
        existingNumbers.add(u.admissionNo.trim().toUpperCase());
      }
    }

    final prefix = 'STU-$currentYear-';
    final pattern = RegExp('^STU-$currentYear-(\\d+)\$');
    int maxSeq = 0;

    for (final adm in existingNumbers) {
      final match = pattern.firstMatch(adm);
      if (match != null) {
        final seq = int.tryParse(match.group(1)!) ?? 0;
        if (seq > maxSeq) {
          maxSeq = seq;
        }
      }
    }

    int nextSeq = maxSeq + 1;
    String candidate = '$prefix${nextSeq.toString().padLeft(4, '0')}';
    while (existingNumbers.contains(candidate)) {
      nextSeq++;
      candidate = '$prefix${nextSeq.toString().padLeft(4, '0')}';
    }

    return candidate;
  }

  Future<UserItem> addUser(UserItem user, {String? password}) async {
    final tempApp = await Firebase.initializeApp(
      name: 'UserRegister_${DateTime.now().millisecondsSinceEpoch}',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    User? createdUser;
    late UserItem finalUser;
    final effectivePassword = (password != null && password.trim().isNotEmpty)
        ? password.trim()
        : generateSecurePassword();

    var processedUser = user;
    if (processedUser.role.toLowerCase() == 'student') {
      if (processedUser.admissionNo.isEmpty) {
        final autoAdmission = await generateUniqueAdmissionNo();
        processedUser = processedUser.copyWith(admissionNo: autoAdmission);
      }
      if (processedUser.email.trim().isEmpty) {
        final cleanAdm = processedUser.admissionNo
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '');
        processedUser = processedUser.copyWith(
          email: '${cleanAdm.isNotEmpty ? cleanAdm : "student"}@student.schoolbridge.lk',
        );
      }
    }

    try {
      final credential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
            email: processedUser.email.trim(),
            password: effectivePassword,
          );
      createdUser = credential.user;
      if (createdUser == null) {
        throw StateError('Authentication user was not created.');
      }
      finalUser = processedUser.copyWith(id: createdUser.uid);
      await ClassAssignmentService(_firestore)
          .save(finalUser.id, finalUser.toMap());
    } catch (_) {
      // Avoid leaving an Auth account without its matching user and roster.
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }
      rethrow;
    } finally {
      await tempApp.delete();
    }
    _users.removeWhere((u) => u.id == finalUser.id);
    _users.insert(0, finalUser);
    _streamController.add(List.unmodifiable(_users));
    return finalUser;
  }

  /// Registers a student and parent together, saving each separately in DB
  /// with proper linking in `users` and `students` collections.
  Future<Map<String, dynamic>> addStudentWithParent({
    required UserItem student,
    required String studentPassword,
    required UserItem parent,
    required String parentPassword,
  }) async {
    final tempApp = await Firebase.initializeApp(
      name: 'StudentParentRegister_${DateTime.now().millisecondsSinceEpoch}',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final auth = FirebaseAuth.instanceFor(app: tempApp);
    User? createdParentUser;
    User? createdStudentUser;
    late UserItem finalParent;
    late UserItem finalStudent;

    // Ensure admission number is generated if not provided
    var processedStudent = student;
    if (processedStudent.admissionNo.trim().isEmpty) {
      final autoAdmission = await generateUniqueAdmissionNo();
      processedStudent = processedStudent.copyWith(admissionNo: autoAdmission);
    }

    // Ensure student email is generated if optional email is empty
    if (processedStudent.email.trim().isEmpty) {
      final cleanAdm = processedStudent.admissionNo
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      processedStudent = processedStudent.copyWith(
        email: '${cleanAdm.isNotEmpty ? cleanAdm : "student"}@student.schoolbridge.lk',
      );
    }

    final effectiveStudentPassword = studentPassword.trim().isNotEmpty
        ? studentPassword.trim()
        : generateSecurePassword();

    final effectiveParentPassword = parentPassword.trim().isNotEmpty
        ? parentPassword.trim()
        : generateSecurePassword();

    try {
      // 1. Create Parent in Firebase Auth
      final parentCred = await auth.createUserWithEmailAndPassword(
        email: parent.email.trim(),
        password: effectiveParentPassword,
      );
      createdParentUser = parentCred.user;
      if (createdParentUser == null) {
        throw StateError('Parent authentication user could not be created.');
      }
      finalParent = parent.copyWith(id: createdParentUser.uid);

      // Save parent separately in Firestore users collection
      await ClassAssignmentService(_firestore)
          .save(finalParent.id, finalParent.toMap());

      // 2. Create Student in Firebase Auth
      final studentCred = await auth.createUserWithEmailAndPassword(
        email: processedStudent.email.trim(),
        password: effectiveStudentPassword,
      );
      createdStudentUser = studentCred.user;
      if (createdStudentUser == null) {
        throw StateError('Student authentication user could not be created.');
      }

      // Link student to the newly created parent's UID
      finalStudent = processedStudent.copyWith(
        id: createdStudentUser.uid,
        parentIds: [finalParent.id],
      );

      // Save student in Firestore users and students collections
      await ClassAssignmentService(_firestore)
          .save(finalStudent.id, finalStudent.toMap());
    } catch (_) {
      // Clean up on failure so no orphaned accounts remain
      if (createdStudentUser != null) {
        try {
          await createdStudentUser.delete();
          await _firestore.collection('users').doc(createdStudentUser.uid).delete();
          await _firestore.collection('students').doc(createdStudentUser.uid).delete();
        } catch (_) {}
      }
      if (createdParentUser != null) {
        try {
          await createdParentUser.delete();
          await _firestore.collection('users').doc(createdParentUser.uid).delete();
        } catch (_) {}
      }
      rethrow;
    } finally {
      await tempApp.delete();
    }

    // Update local cache so admin immediately sees both new users
    _users.removeWhere((u) => u.id == finalParent.id || u.id == finalStudent.id);
    _users.insert(0, finalStudent);
    _users.insert(1, finalParent);
    _streamController.add(List.unmodifiable(_users));

    return {
      'student': finalStudent,
      'parent': finalParent,
      'studentPassword': effectiveStudentPassword,
      'parentPassword': effectiveParentPassword,
    };
  }


  Future<void> updateUser(UserItem updatedUser) async {
    await ClassAssignmentService(_firestore)
        .save(updatedUser.id, updatedUser.toMap());
    final index = _users.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      _users[index] = updatedUser;
      _streamController.add(List.unmodifiable(_users));
    }
  }

  Future<void> deleteUser(String id) async {
    _users.removeWhere((u) => u.id == id);
    _streamController.add(List.unmodifiable(_users));

    try {
      await _firestore.collection('users').doc(id).delete();
    } catch (_) {}
  }
}
