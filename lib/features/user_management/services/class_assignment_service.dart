import 'package:cloud_firestore/cloud_firestore.dart';

class ClassAssignmentService {
  final FirebaseFirestore firestore;
  ClassAssignmentService(this.firestore);

  static String classId(String schoolId, String name) =>
      '${schoolId}_${Uri.encodeComponent(name.trim())}';

  // Keep the user, roster and teacher assignment consistent in one transaction.
  Future<void> save(String uid, Map<String, dynamic> data) async {
    final userRef = firestore.collection('users').doc(uid);
    await firestore.runTransaction((transaction) async {
      final previous = (await transaction.get(userRef)).data();
      final school =
          previous?['schoolId'] as String? ?? data['schoolId'] as String;
      final role = data['role'];
      final name = (data['gradeOrClass'] as String? ?? '').trim();
      final assigned =
          (role == 'teacher' || role == 'student') && name.isNotEmpty;
      final id = assigned ? classId(school, name) : null;
      final oldId = previous?['classId'] as String?;
      final classRef = id == null
          ? null
          : firestore.collection('classes').doc(id);
      final current = classRef == null
          ? null
          : (await transaction.get(classRef)).data();
      final oldRef =
          oldId != null &&
              oldId.isNotEmpty &&
              oldId != id &&
              previous?['role'] == 'teacher'
          ? firestore.collection('classes').doc(oldId)
          : null;
      final oldClass = oldRef == null
          ? null
          : (await transaction.get(oldRef)).data();
      final studentRef = firestore.collection('students').doc(uid);
      final student = (await transaction.get(studentRef)).data();

      List<String> teachers(Map<String, dynamic>? classroom) =>
          classroom?['teacherIds'] is List
          ? List<String>.from(classroom!['teacherIds'] as List)
          : [
              if (classroom?['teacherId'] is String &&
                  classroom!['teacherId'] != '')
                classroom['teacherId'] as String,
            ];

      if (oldRef != null && oldClass != null) {
        final ids = teachers(oldClass)..remove(uid);
        transaction.update(oldRef, {
          'teacherIds': ids,
          'teacherId': ids.isEmpty ? '' : ids.first,
        });
      }
      if (classRef != null) {
        final ids = teachers(current);
        if (role == 'teacher') {
          ids.remove(uid);
          if (data['active'] == true) ids.add(uid);
        } else if (previous?['role'] == 'teacher') {
          ids.remove(uid);
        }
        transaction.set(classRef, {
          'name': name,
          'schoolId': school,
          'teacherIds': ids,
          'teacherId': ids.isEmpty ? '' : ids.first,
        }, SetOptions(merge: true));
      }
      transaction.set(userRef, {
        ...data,
        'schoolId': school,
        'classId': id ?? '',
      }, SetOptions(merge: true));
      if (role == 'student' && id != null) {
        transaction.set(studentRef, {
          'name': data['name'],
          'email': data['email'],
          'classId': id,
          'schoolId': school,
          'active': data['active'],
          'parentIds': data['parentIds'] ?? student?['parentIds'] ?? [],
          'address': data['address'] ?? student?['address'] ?? '',
          'homePhone': data['homePhone'] ?? student?['homePhone'] ?? '',
          'dob': data['dob'] ?? student?['dob'] ?? '',
          'gender': data['gender'] ?? student?['gender'] ?? '',
          'admissionNo': data['admissionNo'] ?? student?['admissionNo'] ?? '',
        }, SetOptions(merge: true));
      } else if (student != null) {
        transaction.delete(studentRef);
      }
    });
  }
}
