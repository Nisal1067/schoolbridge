import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/attendance_record.dart';

class AttendanceService {
  final FirebaseFirestore _firestore;

  AttendanceService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> saveAttendance(List<AttendanceRecord> records) async {
    if (records.isEmpty) {
      throw StateError('This class has no students.');
    }

    if (records.length > 450) {
      throw StateError('Class exceeds the supported batch size.');
    }
    // Each student validation uses a rule document lookup; keep batches below
    // Firestore's 20-access limit. Deterministic IDs make retries idempotent.
    for (int start = 0; start < records.length; start += 15) {
      final batch = _firestore.batch();
      for (final record in records.skip(start).take(15)) {
        // Same class + student + date will use the same document.
        // Saving again updates the existing attendance instead of
        // creating a duplicate.
        final documentId = record.documentId;

        final documentReference = _firestore
            .collection('attendance')
            .doc(documentId);

        batch.set(documentReference, record.toMap());
      }

      await batch.commit();
    }
  }

  Future<Map<String, dynamic>> profile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Please sign in again.');
    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null || data['active'] != true) {
      throw StateError('Your account is not active.');
    }
    return {...data, 'uid': uid};
  }

  Future<List<Map<String, dynamic>>> teacherClasses() async {
    final user = await profile();
    final result = await _firestore
        .collection('classes')
        .where('teacherId', isEqualTo: user['uid'])
        .where('schoolId', isEqualTo: user['schoolId'])
        .get();
    return result.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  Future<List<Map<String, dynamic>>> studentsForClass(
    Map<String, dynamic> classroom,
  ) async {
    final result = await _firestore
        .collection('students')
        .where('classId', isEqualTo: classroom['id'])
        .where('schoolId', isEqualTo: classroom['schoolId'])
        .get();
    final students = result.docs.map((d) => {...d.data(), 'id': d.id}).toList();
    students.sort(
      (a, b) => (a['name'] as String).compareTo(b['name'] as String),
    );
    return students;
  }

  Future<List<Map<String, dynamic>>> linkedStudents() async {
    final user = await profile();
    if (user['role'] == 'student') {
      final doc = await _firestore
          .collection('students')
          .doc(user['uid'])
          .get();
      return doc.exists
          ? [
              {...doc.data()!, 'id': doc.id},
            ]
          : [];
    }
    if (user['role'] != 'parent') {
      throw StateError('Student or parent access required.');
    }
    final result = await _firestore
        .collection('students')
        .where('parentIds', arrayContains: user['uid'])
        .where('schoolId', isEqualTo: user['schoolId'])
        .get();
    return result.docs.map((d) => {...d.data(), 'id': d.id}).toList();
  }

  Stream<List<AttendanceRecord>> classRecords(Map<String, dynamic> classroom) =>
      _records(
        _firestore
            .collection('attendance')
            .where('classId', isEqualTo: classroom['id'])
            .where('schoolId', isEqualTo: classroom['schoolId']),
      );

  Stream<List<AttendanceRecord>> studentRecords(Map<String, dynamic> student) =>
      _records(
        _firestore
            .collection('attendance')
            .where('studentId', isEqualTo: student['id'])
            .where('schoolId', isEqualTo: student['schoolId']),
      );

  Stream<List<AttendanceRecord>> _records(Query<Map<String, dynamic>> query) =>
      query.snapshots().map((snapshot) {
        final records = snapshot.docs
            .map(
              (d) =>
                  AttendanceRecord.fromMap({...d.data(), 'documentId': d.id}),
            )
            .toList();
        records.sort((a, b) => b.date.compareTo(a.date));
        return records;
      });

  Future<void> deleteAttendance(List<AttendanceRecord> records) async {
    if (records.length > 450) {
      throw StateError('Class exceeds the supported batch size.');
    }
    final batch = _firestore.batch();
    for (final record in records) {
      batch.delete(_firestore.collection('attendance').doc(record.documentId));
    }
    await batch.commit();
  }
}
