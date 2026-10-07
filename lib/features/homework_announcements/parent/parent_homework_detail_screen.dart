import 'package:flutter/material.dart';

import '../models/homework.dart';
import '../models/student_homework.dart';
import '../models/submission.dart';
import '../services/parent_homework_service.dart';
import '../widgets/task_widgets.dart';
import 'parent_common.dart';

/// Read-only view of one assignment for a parent: instructions, whether the
/// child has handed it in, and the teacher's feedback.
class ParentHomeworkDetailScreen extends StatefulWidget {
  final String homeworkId;

  /// The child's `students` record (needs `id` and `name`).
  final Map<String, dynamic> child;

  const ParentHomeworkDetailScreen({
    super.key,
    required this.homeworkId,
    required this.child,
  });

  @override
  State<ParentHomeworkDetailScreen> createState() =>
      _ParentHomeworkDetailScreenState();
}

class _ParentHomeworkDetailScreenState
    extends State<ParentHomeworkDetailScreen> {
  final _service = ParentHomeworkService();
  late final Stream<Homework?> _homework = _service.watchHomework(
    widget.homeworkId,
  );
  late final Stream<Submission?> _submission = _service.watchSubmission(
    widget.homeworkId,
    widget.child['id'] as String,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaskColors.background,
      appBar: taskAppBar('Homework Detail'),
      body: SafeArea(
        child: StreamBuilder<Homework?>(
          stream: _homework,
          builder: (context, hwSnapshot) {
            if (hwSnapshot.hasError) {
              return const ParentMessage('Could not load this homework.');
            }
            if (hwSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final homework = hwSnapshot.data;
            if (homework == null) {
              return const ParentMessage(
                'This homework is no longer available.',
              );
            }
            return StreamBuilder<Submission?>(
              stream: _submission,
              builder: (context, subSnapshot) {
                if (subSnapshot.hasError) {
                  return const ParentMessage(
                    'Could not load the submission status.',
                  );
                }
                if (subSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _content(homework, subSnapshot.data);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _card({required Widget child, Color? color}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TaskColors.border),
      ),
      child: child,
    );
  }

  Widget _heading(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w800,
      color: TaskColors.ink,
    ),
  );

  Widget _content(Homework h, Submission? submission) {
    final item = StudentHomework(h, submission);
    final style = homeworkStatusStyle(item.status);
    final name = firstName(widget.child);
    final fullName = widget.child['name'] as String? ?? name;
    final isLate = submission?.isLate(h.dueDate) ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TaskChip(text: h.subject),
                    const Spacer(),
                    TaskChip(
                      text: style.label,
                      background: style.bg,
                      foreground: style.fg,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  h.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: TaskColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: TaskColors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Due Date: ${longDate(h.dueDate)}, 11:59 PM',
                        style: const TextStyle(
                          fontSize: 14,
                          color: TaskColors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (h.className.isNotEmpty) h.className,
                    'Assigned to $fullName',
                  ].join(' • '),
                  style: const TextStyle(fontSize: 13, color: TaskColors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  homeworkDueText(item),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: homeworkDueColor(item),
                  ),
                ),
              ],
            ),
          ),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heading('Instructions'),
                const SizedBox(height: 8),
                const Divider(height: 1, color: TaskColors.border),
                const SizedBox(height: 10),
                Text(
                  h.description.isEmpty
                      ? 'No instructions were added.'
                      : h.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: TaskColors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (submission == null)
            _notSubmittedCard(item, name)
          else
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heading("$name's Submission"),
                  const SizedBox(height: 6),
                  Text(
                    submission.submittedAt == null
                        ? 'Submitted'
                        : 'Submitted ${longDate(submission.submittedAt!)}'
                              '${isLate ? ' (late)' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isLate ? TaskColors.red : TaskColors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    submission.note.isEmpty
                        ? 'No note was added.'
                        : submission.note,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: submission.note.isEmpty
                          ? TaskColors.grey
                          : TaskColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          if (submission != null && submission.isReviewed)
            _card(
              color: TaskColors.greenSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heading('Teacher Feedback'),
                  const SizedBox(height: 8),
                  Text(
                    submission.feedback.isEmpty
                        ? 'The teacher reviewed this homework.'
                        : submission.feedback,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: TaskColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Only students can submit homework. You can follow progress '
              'and feedback here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: TaskColors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notSubmittedCard(StudentHomework item, String name) {
    final overdue = item.status == HomeworkStatus.overdue;
    return _card(
      color: overdue ? TaskColors.redSoft : TaskColors.amberSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            overdue ? Icons.error_outline : Icons.hourglass_empty,
            color: overdue ? TaskColors.red : TaskColors.amber,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              overdue
                  ? "$name hasn't handed this in and it is past the due "
                        'date. You may want to check in with them or the '
                        'teacher.'
                  : "$name hasn't handed this in yet. "
                        '${homeworkDueText(item)}.',
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: TaskColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
