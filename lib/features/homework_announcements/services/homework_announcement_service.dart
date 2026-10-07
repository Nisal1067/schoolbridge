import 'package:cloud_firestore/cloud_firestore.dart';

import '../../attendance/services/attendance_service.dart';
import '../models/announcement.dart';
import '../models/homework.dart';
import '../models/submission.dart';

/// Firestore access for teacher homework and announcements.
///
/// Re-uses [AttendanceService] for the signed-in profile, the teacher's
/// classes and class rosters, so both features share the same data access.
class HomeworkAnnouncementService {
  final FirebaseFirestore _firestore;
  final AttendanceService _attendance;

  HomeworkAnnouncementService({
    FirebaseFirestore? firestore,
    AttendanceService? attendance,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _attendance = attendance ?? AttendanceService();

  Future<List<Map<String, dynamic>>> teacherClasses() =>
      _attendance.teacherClasses();

  // ---------------------------------------------------------------- Homework

  Stream<List<Homework>> watchHomework() async* {
    final user = await _attendance.profile();
    yield* _firestore
        .collection('homework')
        .where('teacherId', isEqualTo: user['uid'])
        .where('schoolId', isEqualTo: user['schoolId'])
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map(Homework.fromDoc).toList();
          // Sorted here so no composite index is needed.
          list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
          return list;
        });
  }

  Stream<Homework?> watchHomeworkById(String id) => _firestore
      .collection('homework')
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? Homework.fromDoc(doc) : null);

  Future<void> createHomework({
    required Map<String, dynamic> classroom,
    required String subject,
    required String title,
    required String description,
    required DateTime dueDate,
  }) async {
    final user = await _attendance.profile();
    final roster = await _attendance.studentsForClass(classroom);
    await _firestore.collection('homework').add({
      'schoolId': classroom['schoolId'],
      'classId': classroom['id'],
      'className': classroom['name'],
      'teacherId': user['uid'],
      'subject': subject,
      'title': title.trim(),
      'description': description.trim(),
      'dueDate': Timestamp.fromDate(_dateOnly(dueDate)),
      'totalStudents': roster.length,
      'submittedCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateHomework(
    Homework homework, {
    required String subject,
    required String title,
    required String description,
    required DateTime dueDate,
  }) {
    return _firestore.collection('homework').doc(homework.id).update({
      'subject': subject,
      'title': title.trim(),
      'description': description.trim(),
      'dueDate': Timestamp.fromDate(_dateOnly(dueDate)),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes the submissions first (Firestore does not cascade), then the
  /// homework itself. The submissions' rules look up the homework document,
  /// so it must still exist while they are deleted.
  Future<void> deleteHomework(String id) async {
    final homeworkRef = _firestore.collection('homework').doc(id);
    final submissions = await homeworkRef.collection('submissions').get();
    // Batches of 15: each delete triggers a rule lookup (20-access limit).
    for (var start = 0; start < submissions.docs.length; start += 15) {
      final batch = _firestore.batch();
      for (final doc in submissions.docs.skip(start).take(15)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
    await homeworkRef.delete();
  }

  // ------------------------------------------------------------ Submissions

  Stream<List<Submission>> watchSubmissions(String homeworkId) => _firestore
      .collection('homework')
      .doc(homeworkId)
      .collection('submissions')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Submission.fromDoc).toList());

  /// Everyone in the homework's class, sorted by name.
  Future<List<Map<String, dynamic>>> rosterFor(Homework homework) =>
      _attendance.studentsForClass({
        'id': homework.classId,
        'schoolId': homework.schoolId,
      });

  Future<void> reviewSubmission({
    required String homeworkId,
    required String studentId,
    required String feedback,
  }) {
    return _firestore
        .collection('homework')
        .doc(homeworkId)
        .collection('submissions')
        .doc(studentId)
        .update({
          'status': 'reviewed',
          'feedback': feedback.trim(),
          'reviewedAt': FieldValue.serverTimestamp(),
        });
  }

  // ----------------------------------------------------------- Announcements

  Stream<List<Announcement>> watchAnnouncements() async* {
    final user = await _attendance.profile();
    yield* _firestore
        .collection('announcements')
        .where('teacherId', isEqualTo: user['uid'])
        .where('schoolId', isEqualTo: user['schoolId'])
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map(Announcement.fromDoc).toList();
          list.sort((a, b) => b.publishAt.compareTo(a.publishAt));
          return list;
        });
  }

  Future<void> createAnnouncement({
    required String title,
    required String body,
    required String audience,
    required String audienceType,
    required String classId,
    required AnnouncementPriority priority,
    required DateTime publishAt,
  }) async {
    final user = await _attendance.profile();
    await _firestore.collection('announcements').add({
      'schoolId': user['schoolId'],
      'teacherId': user['uid'],
      'title': title.trim(),
      'body': body.trim(),
      'audience': audience,
      'audienceType': audienceType,
      'classId': classId,
      'priority': priority.name,
      'publishAt': Timestamp.fromDate(publishAt),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateAnnouncement(
    Announcement announcement, {
    required String title,
    required String body,
    required String audience,
    required String audienceType,
    required String classId,
    required AnnouncementPriority priority,
    required DateTime publishAt,
  }) {
    // Only editable fields are sent; schoolId, teacherId and createdAt stay.
    return _firestore.collection('announcements').doc(announcement.id).update({
      'title': title.trim(),
      'body': body.trim(),
      'audience': audience,
      'audienceType': audienceType,
      'classId': classId,
      'priority': priority.name,
      'publishAt': Timestamp.fromDate(publishAt),
    });
  }

  Future<void> deleteAnnouncement(String id) =>
      _firestore.collection('announcements').doc(id).delete();

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}