import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../firebase_options.dart';
import '../models/user_item.dart';

class UserManagementService {
  static final UserManagementService _instance = UserManagementService._internal();
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
      _firestore.collection('users').snapshots().listen(
        (snapshot) async {
          _errorMessage = null;
          final List<UserItem> realUsers = [];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            realUsers.add(UserItem.fromMap(data, doc.id));
          }

          // Check if students are also stored in students collection
          try {
            final studentSnap = await _firestore.collection('students').get();
            for (final sDoc in studentSnap.docs) {
              final sData = sDoc.data();
              final sName = sData['name'] ?? '';
              final alreadyAdded = realUsers.any(
                (u) => u.id == sDoc.id || (u.name.isNotEmpty && u.name == sName),
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
    String finalUid = user.id;

    // Automatically register account in Firebase Authentication so user can log in immediately
    if (user.email.isNotEmpty) {
      final userPass = (password != null && password.trim().isNotEmpty)
          ? password.trim()
          : '123456';

      try {
        final tempApp = await Firebase.initializeApp(
          name: 'UserRegister_${DateTime.now().millisecondsSinceEpoch}',
          options: DefaultFirebaseOptions.currentPlatform,
        );
        try {
          final secondaryAuth = FirebaseAuth.instanceFor(app: tempApp);
          final cred = await secondaryAuth.createUserWithEmailAndPassword(
            email: user.email.trim(),
            password: userPass,
          );
          if (cred.user != null) {
            finalUid = cred.user!.uid;
          }
        } finally {
          await tempApp.delete();
        }
      } catch (_) {
        // Fallback: If auth creation fails (already registered or web restrictions), continue saving to Firestore
      }
    }

    final finalUser = user.copyWith(id: finalUid);

    try {
      await _firestore.collection('users').doc(finalUid).set(
        finalUser.toMap(),
        SetOptions(merge: true),
      );
      _users.removeWhere((u) => u.id == finalUid);
      _users.insert(0, finalUser);
      _streamController.add(List.unmodifiable(_users));
    } catch (_) {
      final docRef = await _firestore.collection('users').add(finalUser.toMap());
      final newUserWithId = finalUser.copyWith(id: docRef.id);
      _users.removeWhere((u) => u.id == newUserWithId.id);
      _users.insert(0, newUserWithId);
      _streamController.add(List.unmodifiable(_users));
    }
  }

  Future<void> updateUser(UserItem updatedUser) async {
    final index = _users.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      _users[index] = updatedUser;
      _streamController.add(List.unmodifiable(_users));
    }

    try {
      await _firestore.collection('users').doc(updatedUser.id).update(updatedUser.toMap());
    } catch (_) {}
  }

  Future<void> deleteUser(String id) async {
    _users.removeWhere((u) => u.id == id);
    _streamController.add(List.unmodifiable(_users));

    try {
      await _firestore.collection('users').doc(id).delete();
    } catch (_) {}
  }
}
