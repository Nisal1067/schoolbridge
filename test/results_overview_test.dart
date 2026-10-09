import 'package:flutter_test/flutter_test.dart';
import 'package:schoolbridge/features/marks/models/mark_record.dart';
import 'package:schoolbridge/features/marks/models/results_overview.dart';

MarkRecord mark(String subject, int mark, {int term = 2}) => MarkRecord(
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
  changeTests();

  test('Only the chosen term is included, sorted by subject name', () {
    final overview = ResultsOverview.forTerm([
      mark('Science', 70),
      mark('english', 80),
      mark('Mathematics', 90, term: 1),
    ], 2);
    expect(overview.subjects.map((m) => m.subject), ['english', 'Science']);
  });

  test('Average and best subject are calculated', () {
    final overview = ResultsOverview.forTerm([
      mark('Mathematics', 92),
      mark('Science', 70),
      mark('English', 51),
    ], 2);
    expect(overview.average, closeTo(71.0, 0.001));
    expect(overview.best?.subject, 'Mathematics');
    expect(overview.isEmpty, false);
  });

  test('A term with no marks is empty', () {
    final overview = ResultsOverview.forTerm([mark('Science', 70)], 3);
    expect(overview.isEmpty, true);
    expect(overview.average, 0);
    expect(overview.best, isNull);
  });
}

void changeTests() {
  group('change since previous term', () {
    final term1 = ResultsOverview.forTerm([
      mark('Mathematics', 80, term: 1),
      mark('Science', 60, term: 1),
    ], 1);
    final term2 = ResultsOverview.forTerm([
      mark('mathematics', 90),
      mark('English', 70),
    ], 2);

    test('average change is current minus previous', () {
      expect(term2.averageChange(term1), closeTo(10.0, 0.001));
    });

    test('subject change matches subjects ignoring case', () {
      expect(term2.subjectChange('Mathematics', term1), 10);
    });

    test('subject missing in either term gives no change', () {
      expect(term2.subjectChange('English', term1), isNull);
      expect(term2.subjectChange('Science', term1), isNull);
    });

    test('empty terms give no average change', () {
      final empty = ResultsOverview.forTerm([], 3);
      expect(empty.averageChange(term2), isNull);
      expect(term2.averageChange(empty), isNull);
    });
  });
}
