import 'package:cloud_firestore/cloud_firestore.dart';

import '../../attendance/services/attendance_service.dart';
import '../models/mark_record.dart';

/// Reads marks for the student side (own marks) and the parent side
/// (marks of each linked child) from the `marks` collection.
class StudentMarksService {
  final FirebaseFirestore _firestore;
  final AttendanceService _attendance;

  StudentMarksService({
    FirebaseFirestore? firestore,
    AttendanceService? attendance,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _attendance = attendance ?? AttendanceService(firestore: firestore);

  /// The signed-in student, or the parent's linked children
  /// (`students` documents, each with `id`, `name`, `schoolId`, ...).
  Future<List<Map<String, dynamic>>> linkedStudents() =>
      _attendance.linkedStudents();

  /// Every mark (all terms) for [student], updating live when a teacher
  /// saves. Streams can be listened to once, so create them in `initState`
  /// or when the selection changes, never inside `build`.
  Stream<List<MarkRecord>> watchStudentMarks(Map<String, dynamic> student) =>
      _firestore
          .collection('marks')
          .where('studentId', isEqualTo: student['id'])
          .where('schoolId', isEqualTo: student['schoolId'])
          .snapshots()
          .map(
            (snapshot) => [
              for (final doc in snapshot.docs) MarkRecord.fromMap(doc.data()),
            ],
          );

  /// The signed-in student's own marks.
  Stream<List<MarkRecord>> watchMyMarks() async* {
    final students = await linkedStudents();
    if (students.isEmpty) {
      throw StateError(
        'Your student profile was not found. Please contact your school.',
      );
    }
    yield* watchStudentMarks(students.first);
  }
}
