import 'package:cloud_firestore/cloud_firestore.dart';

import '../../attendance/services/attendance_service.dart';
import '../models/mark_record.dart';

/// Reads the signed-in student's own marks from the `marks` collection.
class StudentMarksService {
  final FirebaseFirestore _firestore;
  final AttendanceService _attendance;

  StudentMarksService({
    FirebaseFirestore? firestore,
    AttendanceService? attendance,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _attendance = attendance ?? AttendanceService(firestore: firestore);

  /// All of the student's marks (every term), updating live when a teacher
  /// saves. The stream can only be listened to once, so create it in
  /// `initState`, not in `build`.
  Stream<List<MarkRecord>> watchMyMarks() async* {
    final students = await _attendance.linkedStudents();
    if (students.isEmpty) {
      throw StateError(
        'Your student profile was not found. Please contact your school.',
      );
    }
    final student = students.first;
    yield* _firestore
        .collection('marks')
        .where('studentId', isEqualTo: student['id'])
        .where('schoolId', isEqualTo: student['schoolId'])
        .snapshots()
        .map(
          (snapshot) => [
            for (final doc in snapshot.docs) MarkRecord.fromMap(doc.data()),
          ],
        );
  }
}
