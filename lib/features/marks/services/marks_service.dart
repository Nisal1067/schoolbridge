import 'package:cloud_firestore/cloud_firestore.dart';

import '../../attendance/services/attendance_service.dart';
import '../models/mark_record.dart';

/// Reads and writes the `marks` collection for the signed-in teacher.
///
/// Profile, class and student lookups reuse [AttendanceService] so both
/// screens always show the same classes and rosters.
class MarksService {
  /// Shown when the teacher profile has no subjects configured.
  static const defaultSubjects = [
    'Mathematics',
    'Science',
    'English',
    'History',
    'Geography',
    'ICT',
  ];

  // Same limit as attendance: each write's rule reads the student document, so
  // keep batches under Firestore's 20-access limit.
  static const _batchSize = 15;

  final FirebaseFirestore _firestore;
  final AttendanceService _roster;

  MarksService({FirebaseFirestore? firestore, AttendanceService? roster})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _roster = roster ?? AttendanceService(firestore: firestore);

  Future<Map<String, dynamic>> profile() => _roster.profile();

  Future<List<Map<String, dynamic>>> classes() async {
    final list = await _roster.teacherClasses();
    list.sort((a, b) => '${a['name'] ?? ''}'.compareTo('${b['name'] ?? ''}'));
    return list;
  }

  Future<List<Map<String, dynamic>>> students(Map<String, dynamic> classroom) =>
      _roster.studentsForClass(classroom);

  /// Subjects from the teacher profile (`subjects` list or `subject` string),
  /// or [defaultSubjects] when none are set.
  static List<String> subjectsFor(Map<String, dynamic> profile) {
    final raw = profile['subjects'] ?? profile['subject'];
    final values = raw is List
        ? raw.map((v) => v.toString().trim())
        : raw is String
        ? [raw.trim()]
        : <String>[];
    final unique = <String>{
      for (final v in values)
        if (v.isNotEmpty) v,
    }.toList();
    return unique.isEmpty ? List.of(defaultSubjects) : unique;
  }

  /// Saved marks for one class, subject and term, keyed by student id.
  Future<Map<String, MarkRecord>> loadMarks({
    required Map<String, dynamic> classroom,
    required String subject,
    required int term,
  }) async {
    final result = await _firestore
        .collection('marks')
        .where('classId', isEqualTo: classroom['id'])
        .where('schoolId', isEqualTo: classroom['schoolId'])
        .where('subject', isEqualTo: subject)
        .where('term', isEqualTo: term)
        .get();
    final records = result.docs.map((d) => MarkRecord.fromMap(d.data()));
    return {for (final record in records) record.studentId: record};
  }

  /// Creates or updates [upserts] and removes [deletes] (cleared marks).
  Future<void> saveMarks({
    List<MarkRecord> upserts = const [],
    List<MarkRecord> deletes = const [],
  }) async {
    for (final record in upserts) {
      if (record.mark < 0 || record.mark > MarkGrading.maxMark) {
        throw StateError('Marks must be between 0 and 100.');
      }
    }
    final writes = <({MarkRecord record, bool delete})>[
      for (final r in upserts) (record: r, delete: false),
      for (final r in deletes) (record: r, delete: true),
    ];
    if (writes.length > 450) {
      throw StateError('Class exceeds the supported batch size.');
    }
    for (var start = 0; start < writes.length; start += _batchSize) {
      final batch = _firestore.batch();
      for (final write in writes.skip(start).take(_batchSize)) {
        final ref = _firestore.collection('marks').doc(write.record.documentId);
        if (write.delete) {
          batch.delete(ref);
        } else {
          batch.set(ref, write.record.toMap());
        }
      }
      await batch.commit();
    }
  }
}
