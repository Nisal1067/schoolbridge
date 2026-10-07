import 'package:flutter_test/flutter_test.dart';
import 'package:schoolbridge/features/homework_announcements/models/homework.dart';
import 'package:schoolbridge/features/homework_announcements/models/student_homework.dart';
import 'package:schoolbridge/features/homework_announcements/models/submission.dart';
import 'package:schoolbridge/features/homework_announcements/parent/parent_common.dart';

Homework _homework(DateTime due) => Homework(
  id: 'h1',
  schoolId: 's1',
  classId: 'c1',
  className: 'Grade 10A',
  teacherId: 't1',
  subject: 'Mathematics',
  title: 'Algebra worksheet',
  description: '',
  dueDate: due,
  totalStudents: 30,
  submittedCount: 0,
  createdAt: DateTime(2026, 10, 1),
);

Submission _submission({String status = 'submitted'}) => Submission(
  studentId: 'st1',
  studentName: 'Kasun',
  status: status,
  note: '',
  feedback: '',
  submittedAt: DateTime(2026, 10, 7, 9),
);

void main() {
  // "Today" is fixed so the tests do not depend on the real clock.
  final now = DateTime(2026, 10, 7, 12);

  group('homeworkDueText', () {
    test('counts days left, tomorrow and today', () {
      expect(
        homeworkDueText(
          StudentHomework(_homework(DateTime(2026, 10, 12)), null),
          now: now,
        ),
        '5 days left',
      );
      expect(
        homeworkDueText(
          StudentHomework(_homework(DateTime(2026, 10, 8)), null),
          now: now,
        ),
        'Due tomorrow',
      );
      expect(
        homeworkDueText(
          StudentHomework(_homework(DateTime(2026, 10, 7)), null),
          now: now,
        ),
        'Due today',
      );
    });

    test('counts days overdue', () {
      expect(
        homeworkDueText(
          StudentHomework(_homework(DateTime(2026, 10, 6)), null),
          now: now,
        ),
        '1 day overdue',
      );
      expect(
        homeworkDueText(
          StudentHomework(_homework(DateTime(2026, 10, 3)), null),
          now: now,
        ),
        '4 days overdue',
      );
    });

    test('shows submitted and reviewed work as done', () {
      final due = _homework(DateTime(2026, 10, 3));
      expect(
        homeworkDueText(StudentHomework(due, _submission()), now: now),
        'Submitted 07 Oct',
      );
      expect(
        homeworkDueText(
          StudentHomework(due, _submission(status: 'reviewed')),
          now: now,
        ),
        'Reviewed by teacher',
      );
    });
  });

  group('isDueSoon', () {
    test('is true only for unfinished work due today or tomorrow', () {
      final today = StudentHomework(_homework(DateTime(2026, 10, 7)), null);
      final tomorrow = StudentHomework(_homework(DateTime(2026, 10, 8)), null);
      final later = StudentHomework(_homework(DateTime(2026, 10, 9)), null);
      final done = StudentHomework(
        _homework(DateTime(2026, 10, 7)),
        _submission(),
      );
      expect(isDueSoon(today, now: now), isTrue);
      expect(isDueSoon(tomorrow, now: now), isTrue);
      expect(isDueSoon(later, now: now), isFalse);
      expect(isDueSoon(done, now: now), isFalse);
    });
  });

  test('firstName and initialOf handle empty names', () {
    expect(firstName({'name': 'Kasun Perera'}), 'Kasun');
    expect(firstName({'name': '  '}), 'Your child');
    expect(initialOf({'name': 'kasun'}), 'K');
    expect(initialOf({}), '?');
  });
}
