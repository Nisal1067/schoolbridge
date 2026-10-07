import 'homework.dart';
import 'submission.dart';

enum HomeworkStatus { pending, overdue, submitted, reviewed }

/// One homework assignment together with this student's own submission.
class StudentHomework {
  final Homework homework;
  final Submission? submission;

  const StudentHomework(this.homework, this.submission);

  bool get isDone => submission != null;

  HomeworkStatus get status {
    final s = submission;
    if (s != null) {
      return s.isReviewed ? HomeworkStatus.reviewed : HomeworkStatus.submitted;
    }
    return homework.isActive ? HomeworkStatus.pending : HomeworkStatus.overdue;
  }
}
