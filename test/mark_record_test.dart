import 'package:flutter_test/flutter_test.dart';
import 'package:schoolbridge/features/marks/models/mark_record.dart';
import 'package:schoolbridge/features/marks/services/marks_service.dart';

MarkRecord record({
  int mark = 85,
  String subject = 'Mathematics',
  int term = 3,
}) => MarkRecord(
  studentId: 'stu1',
  studentName: 'Amaya S.',
  classId: 'class10a',
  schoolId: 'school01',
  teacherId: 'teacher1',
  subject: subject,
  term: term,
  mark: mark,
);

void main() {
  test('Grade bands change exactly at the boundaries', () {
    expect(MarkGrading.bandFor(100), MarkBand.a);
    expect(MarkGrading.bandFor(75), MarkBand.a);
    expect(MarkGrading.bandFor(74), MarkBand.b);
    expect(MarkGrading.bandFor(65), MarkBand.b);
    expect(MarkGrading.bandFor(64), MarkBand.c);
    expect(MarkGrading.bandFor(50), MarkBand.c);
    expect(MarkGrading.bandFor(49), MarkBand.s);
    expect(MarkGrading.bandFor(35), MarkBand.s);
    expect(MarkGrading.bandFor(34), MarkBand.w);
    expect(MarkGrading.bandFor(0), MarkBand.w);
  });

  test('Same student, subject and term always use the same document', () {
    expect(record(mark: 50).documentId, record(mark: 90).documentId);
    expect(record().documentId, 'school01_class10a_mathematics_t3_stu1');
  });

  test('Different subject or term gives a different document', () {
    expect(record().documentId, isNot(record(subject: 'Science').documentId));
    expect(record().documentId, isNot(record(term: 2).documentId));
  });

  test('Subject names with spaces or slashes stay valid document ids', () {
    final id = record(subject: 'Art / Craft').documentId;
    expect(id.contains('/'), false);
    expect(id.contains(' '), false);
    expect(id, isNot(record(subject: 'Art Craft').documentId));
  });

  test('toMap writes exactly the fields the security rules allow', () {
    expect(record().toMap().keys.toSet(), {
      'studentId',
      'studentName',
      'classId',
      'schoolId',
      'teacherId',
      'subject',
      'term',
      'mark',
      'updatedAt',
    });
  });

  test('fromMap tolerates missing fields and numeric types', () {
    final restored = MarkRecord.fromMap({'studentId': 's', 'mark': 72.0});
    expect(restored.mark, 72);
    expect(restored.term, 1);
    expect(restored.subject, '');
  });

  test('Summary of no marks is all zeros', () {
    final summary = MarkSummary.of([], totalStudents: 7);
    expect(summary.entered, 0);
    expect(summary.total, 7);
    expect(summary.average, 0);
    expect(summary.passRate, 0);
    expect(summary.distribution.values.every((v) => v == 0), true);
  });

  test('Summary computes average, range, pass rate and distribution', () {
    final summary = MarkSummary.of([85, 78, 92, 67, 30], totalStudents: 7);
    expect(summary.entered, 5);
    expect(summary.average, closeTo(70.4, 0.001));
    expect(summary.highest, 92);
    expect(summary.lowest, 30);
    expect(summary.passRate, 80);
    expect(summary.distribution[MarkBand.a], 3);
    expect(summary.distribution[MarkBand.b], 1);
    expect(summary.distribution[MarkBand.w], 1);
  });

  group('subjectsFor', () {
    test('uses the profile subjects list without blanks or duplicates', () {
      expect(
        MarksService.subjectsFor({
          'subjects': ['Science', ' ', 'Science', 'English'],
        }),
        ['Science', 'English'],
      );
    });

    test('accepts a single subject string', () {
      expect(MarksService.subjectsFor({'subject': 'Mathematics'}), [
        'Mathematics',
      ]);
    });

    test('falls back to the default list', () {
      expect(MarksService.subjectsFor({}), MarksService.defaultSubjects);
    });
  });
}
