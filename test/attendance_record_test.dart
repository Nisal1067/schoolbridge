import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schoolbridge/features/attendance/models/attendance_record.dart';

AttendanceRecord record(String status, {String school = 'school01'}) =>
    AttendanceRecord(
      studentId: 'student',
      studentName: 'Test Student',
      classId: 'classA',
      schoolId: school,
      teacherId: 'teacher',
      date: DateTime(2026, 10, 4),
      status: status,
      term: 3,
    );

void main() {
  test('Date chooses the term across New Year and September boundaries', () {
    expect(AttendanceRecord.termForDate(DateTime(2026, 1, 1)), 1);
    expect(AttendanceRecord.termForDate(DateTime(2026, 4, 14)), 1);
    expect(AttendanceRecord.termForDate(DateTime(2026, 4, 15)), 2);
    expect(AttendanceRecord.termForDate(DateTime(2026, 8, 31)), 2);
    expect(AttendanceRecord.termForDate(DateTime(2026, 9, 1)), 3);
    expect(AttendanceRecord.termForDate(DateTime(2026, 10, 7)), 3);
    expect(AttendanceRecord.termForDate(DateTime(2026, 11, 30)), 3);
    expect(AttendanceRecord.termForDate(DateTime(2026, 12, 31)), 3);
  });
  test(
    'Loaded document ID is retained for updating and deleting older records',
    () {
      final restored = AttendanceRecord.fromMap({
        'documentId': 'legacy-record',
        'date': Timestamp.fromDate(DateTime(2026)),
      });
      expect(restored.documentId, 'legacy-record');
      expect(restored.toMap().containsKey('documentId'), false);
    },
  );
  test('Attendance counts late as attended and handles empty terms', () {
    expect(AttendanceRecord.summary([])['attendance'], 0);
    final stats = AttendanceRecord.summary([
      record('P'),
      record('A'),
      record('L'),
    ]);
    expect(stats, {
      'present': 1,
      'absent': 1,
      'late': 1,
      'totalDays': 3,
      'attendance': 67,
    });
  });
  test('Record IDs isolate schools and remain stable for updates', () {
    expect(record('P').documentId, record('A').documentId);
    expect(
      record('P').documentId,
      isNot(record('P', school: 'school02').documentId),
    );
  });
  test('Firestore record deserialization preserves date and identity', () {
    final original = record('L');
    final restored = AttendanceRecord.fromMap({
      'studentId': original.studentId,
      'studentName': original.studentName,
      'classId': original.classId,
      'schoolId': original.schoolId,
      'teacherId': original.teacherId,
      'date': Timestamp.fromDate(original.date),
      'status': original.status,
      'term': original.term,
    });
    expect(restored.documentId, original.documentId);
    expect(restored.status, 'L');
    expect(restored.term, 3);
  });
}
