import 'dart:async';

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

  Future<void> addUser(UserItem user, {String? password}) async {
    final tempApp = await Firebase.initializeApp(
      name: 'UserRegister_${DateTime.now().millisecondsSinceEpoch}',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    User? createdUser;
    late UserItem finalUser;
    try {
      final credential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
            email: user.email.trim(),
            password: password?.trim().isNotEmpty == true
                ? password!.trim()
                : '123456',
          );
      createdUser = credential.user;
      if (createdUser == null) {
        throw StateError('Authentication user was not created.');
      }
      finalUser = user.copyWith(id: createdUser.uid);
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
