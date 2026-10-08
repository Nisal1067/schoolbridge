import 'package:flutter/material.dart';

import '../models/announcement.dart';
import '../models/homework.dart';
import '../models/student_homework.dart';
import '../widgets/task_widgets.dart';

/// Label and colours for a homework status chip.
typedef StatusStyle = ({String label, Color bg, Color fg});

StatusStyle homeworkStatusStyle(HomeworkStatus status) => switch (status) {
  HomeworkStatus.pending => (
    label: 'Pending',
    bg: TaskColors.amberSoft,
    fg: TaskColors.amber,
  ),
  HomeworkStatus.overdue => (
    label: 'Overdue',
    bg: TaskColors.redSoft,
    fg: TaskColors.red,
  ),
  HomeworkStatus.submitted => (
    label: 'Submitted',
    bg: TaskColors.greenSoft,
    fg: TaskColors.green,
  ),
  HomeworkStatus.reviewed => (
    label: 'Reviewed',
    bg: TaskColors.greenSoft,
    fg: TaskColors.green,
  ),
};

/// Whole days from [now] until the due date (negative once overdue).
/// Uses UTC dates so daylight-saving changes cannot shift the result.
int daysUntilDue(Homework homework, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime.utc(n.year, n.month, n.day);
  final d = homework.dueDate;
  return DateTime.utc(d.year, d.month, d.day).difference(today).inDays;
}

/// Not handed in yet and due today or tomorrow.
bool isDueSoon(StudentHomework item, {DateTime? now}) =>
    !item.isDone &&
    daysUntilDue(item.homework, now: now) >= 0 &&
    daysUntilDue(item.homework, now: now) <= 1;

/// Short sentence for a homework tile, e.g. "Due tomorrow" or "2 days overdue".
String homeworkDueText(StudentHomework item, {DateTime? now}) {
  final s = item.submission;
  if (s != null) {
    if (s.isReviewed) return 'Reviewed by teacher';
    final at = s.submittedAt;
    return at == null ? 'Submitted' : 'Submitted ${shortDate(at)}';
  }
  final days = daysUntilDue(item.homework, now: now);
  if (days > 1) return '$days days left';
  if (days == 1) return 'Due tomorrow';
  if (days == 0) return 'Due today';
  final daysLate = -days;
  return daysLate == 1 ? '1 day overdue' : '$daysLate days overdue';
}

Color homeworkDueColor(StudentHomework item, {DateTime? now}) {
  switch (item.status) {
    case HomeworkStatus.overdue:
      return TaskColors.red;
    case HomeworkStatus.pending:
      return isDueSoon(item, now: now) ? TaskColors.amber : TaskColors.grey;
    case HomeworkStatus.submitted:
    case HomeworkStatus.reviewed:
      return TaskColors.green;
  }
}

/// First word of a child's name, for friendly sentences.
String firstName(Map<String, dynamic> student) {
  final name = (student['name'] as String? ?? '').trim();
  if (name.isEmpty) return 'Your child';
  return name.split(RegExp(r'\s+')).first;
}

String initialOf(Map<String, dynamic> student) {
  final name = (student['name'] as String? ?? '').trim();
  return name.isEmpty ? '?' : name[0].toUpperCase();
}

// ------------------------------------------------------------ Announcements

/// "2h ago", "1d ago", or a short date for older items.
String timeAgo(DateTime d, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return shortDate(d);
}

/// Published within the last 24 hours.
bool isNewAnnouncement(Announcement a, {DateTime? now}) =>
    (now ?? DateTime.now()).difference(a.publishAt).inHours < 24;

({Color fg, Color bg}) priorityColors(AnnouncementPriority p) => switch (p) {
  AnnouncementPriority.urgent => (fg: TaskColors.red, bg: TaskColors.redSoft),
  AnnouncementPriority.important => (
    fg: TaskColors.amber,
    bg: TaskColors.amberSoft,
  ),
  AnnouncementPriority.normal => (fg: TaskColors.blue, bg: TaskColors.blueSoft),
};

// ------------------------------------------------------------ Shared widgets

/// Row of child "pills" used when a parent has more than one child.
class ChildSelector extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  final int selected;
  final ValueChanged<int> onChanged;

  const ChildSelector({
    super.key,
    required this.students,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < students.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                  decoration: BoxDecoration(
                    color: i == selected ? TaskColors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: i == selected
                          ? TaskColors.blue
                          : TaskColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: i == selected
                            ? Colors.white
                            : TaskColors.blueSoft,
                        child: Text(
                          initialOf(students[i]),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: TaskColors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        firstName(students[i]),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: i == selected ? Colors.white : TaskColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Wrap of filter chips in the same style as the teacher screen.
class FilterChips extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const FilterChips({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (var i = 0; i < labels.length; i++)
          ChoiceChip(
            label: Text(labels[i]),
            selected: selected == i,
            showCheckmark: false,
            onSelected: (_) => onChanged(i),
            selectedColor: TaskColors.blue,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected == i ? TaskColors.blue : TaskColors.border,
            ),
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected == i ? Colors.white : TaskColors.grey,
            ),
          ),
      ],
    );
  }
}

/// Centered grey message, optionally with a Retry button.
class ParentMessage extends StatelessWidget {
  final String text;
  final VoidCallback? onRetry;
  final double top;

  const ParentMessage(this.text, {super.key, this.onRetry, this.top = 40});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, top, 24, 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: TaskColors.grey, fontSize: 15),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
