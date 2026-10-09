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
