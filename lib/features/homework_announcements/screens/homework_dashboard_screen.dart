import 'package:flutter/material.dart';

import '../models/homework.dart';
import '../models/submission.dart';
import '../services/homework_announcement_service.dart';
import '../widgets/task_widgets.dart';

enum _StudentState { pending, submitted, reviewed }

class _Row {
  final String studentId;
  final String name;
  final Submission? submission;
  const _Row(this.studentId, this.name, this.submission);

  _StudentState get state {
    final s = submission;
    if (s == null) return _StudentState.pending;
    return s.isReviewed ? _StudentState.reviewed : _StudentState.submitted;
  }
}

/// Teacher view of one assignment: who has handed in, and review feedback.
class HomeworkDashboardScreen extends StatefulWidget {
  final Homework homework;
  const HomeworkDashboardScreen({super.key, required this.homework});

  @override
  State<HomeworkDashboardScreen> createState() =>
      _HomeworkDashboardScreenState();
}

class _HomeworkDashboardScreenState extends State<HomeworkDashboardScreen> {
  final _service = HomeworkAnnouncementService();
  late final Future<List<Map<String, dynamic>>> _roster = _service.rosterFor(
    widget.homework,
  );
  late final Stream<List<Submission>> _submissions = _service.watchSubmissions(
    widget.homework.id!,
  );

  // null = all students
  _StudentState? _filter;

  List<_Row> _merge(
    List<Map<String, dynamic>> roster,
    List<Submission> submissions,
  ) {
    final byStudent = {for (final s in submissions) s.studentId: s};
    final rows = [
      for (final student in roster)
        _Row(
          student['id'] as String,
          student['name'] as String? ?? 'Student',
          byStudent[student['id']],
        ),
    ];
    // A student who submitted and then left the class still shows up.
    for (final s in submissions) {
      if (!roster.any((r) => r['id'] == s.studentId)) {
        rows.add(
          _Row(
            s.studentId,
            s.studentName.isEmpty ? 'Student' : s.studentName,
            s,
          ),
        );
      }
    }
    return rows;
  }

  Future<void> _openStudent(_Row row) async {
    final submission = row.submission;
    if (submission == null) {
      showTaskSnack(context, '${row.name} has not submitted yet.');
      return;
    }
    // The sheet owns its text controller (see _ReviewSheet), so it is only
    // disposed once the sheet has finished closing. Returns the feedback text,
    // or null when the teacher dismissed the sheet.
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ReviewSheet(
        name: row.name,
        submission: submission,
        dueDate: widget.homework.dueDate,
      ),
    );
    if (text == null || !mounted) return;
    try {
      await _service.reviewSubmission(
        homeworkId: widget.homework.id!,
        studentId: row.studentId,
        feedback: text,
      );
      if (mounted) showTaskSnack(context, 'Marked as reviewed.');
    } catch (_) {
      if (mounted) showTaskSnack(context, 'Could not save the review.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.homework;
    return Scaffold(
      backgroundColor: TaskColors.background,
      appBar: taskAppBar('Homework Dashboard'),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _roster,
          builder: (context, rosterSnapshot) {
            if (rosterSnapshot.hasError) {
              return const Center(
                child: Text('Could not load the class list.'),
              );
            }
            if (!rosterSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return StreamBuilder<List<Submission>>(
              stream: _submissions,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Could not load submissions.'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = _merge(rosterSnapshot.data!, snapshot.data!);
                return _body(h, rows);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _body(Homework h, List<_Row> rows) {
    int count(_StudentState s) => rows.where((r) => r.state == s).length;
    final submitted = count(_StudentState.submitted);
    final reviewed = count(_StudentState.reviewed);
    final pending = count(_StudentState.pending);
    final handedIn = submitted + reviewed;
    final progress = rows.isEmpty ? 0.0 : handedIn / rows.length;

    final visible = rows.where((r) => _filter == null || r.state == _filter);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: TaskColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                h.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: TaskColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${h.className}  •  Due ${longDate(h.dueDate)}',
                style: const TextStyle(fontSize: 13, color: TaskColors.grey),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    '$handedIn / ${rows.length} handed in',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: TaskColors.blue,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 13,
                      color: TaskColors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: TaskColors.border,
                  color: TaskColors.blue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _stat('Pending', pending, TaskColors.amber, TaskColors.amberSoft),
            const SizedBox(width: 8),
            _stat('To review', submitted, TaskColors.blue, TaskColors.blueSoft),
            const SizedBox(width: 8),
            _stat('Reviewed', reviewed, TaskColors.green, TaskColors.greenSoft),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('All', null),
              _filterChip('Pending', _StudentState.pending),
              _filterChip('To review', _StudentState.submitted),
              _filterChip('Reviewed', _StudentState.reviewed),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                'No students in this class yet.',
                style: TextStyle(color: TaskColors.grey),
              ),
            ),
          )
        else if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                'No students match this filter.',
                style: TextStyle(color: TaskColors.grey),
              ),
            ),
          )
        else
          for (final row in visible) _studentTile(h, row),
      ],
    );
  }

  Widget _stat(String label, int value, Color color, Color soft) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, _StudentState? value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: TaskColors.blue,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? TaskColors.blue : TaskColors.border),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : TaskColors.grey,
        ),
      ),
    );
  }

  Widget _studentTile(Homework h, _Row row) {
    final late = row.submission?.isLate(h.dueDate) ?? false;
    final (label, bg, fg) = switch (row.state) {
      _StudentState.pending => (
        'Pending',
        TaskColors.amberSoft,
        TaskColors.amber,
      ),
      _StudentState.submitted => (
        'To review',
        TaskColors.blueSoft,
        TaskColors.blue,
      ),
      _StudentState.reviewed => (
        'Reviewed',
        TaskColors.greenSoft,
        TaskColors.green,
      ),
    };
    final initial = row.name.isEmpty ? '?' : row.name[0].toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openStudent(row),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: TaskColors.blueSoft,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: TaskColors.blue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: TaskColors.ink,
                      ),
                    ),
                    if (row.submission?.submittedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${late ? 'Late • ' : ''}'
                          '${shortDate(row.submission!.submittedAt!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: late ? TaskColors.red : TaskColors.grey,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              TaskChip(text: label, background: bg, foreground: fg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet where a teacher reads a student's note and writes feedback.
///
/// It is its own widget so the [TextEditingController] lives exactly as long
/// as the sheet. Disposing a controller right after `showModalBottomSheet`
/// returns is a bug: the sheet is still animating out and its TextField would
/// use the disposed controller.
class _ReviewSheet extends StatefulWidget {
  final String name;
  final Submission submission;
  final DateTime dueDate;

  const _ReviewSheet({
    required this.name,
    required this.submission,
    required this.dueDate,
  });

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late final TextEditingController _feedback = TextEditingController(
    text: widget.submission.feedback,
  );

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submission = widget.submission;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: TaskColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                submission.submittedAt == null
                    ? 'Submitted'
                    : 'Submitted ${longDate(submission.submittedAt!)}'
                          '${submission.isLate(widget.dueDate) ? ' (late)' : ''}',
                style: const TextStyle(fontSize: 13, color: TaskColors.grey),
              ),
              const SizedBox(height: 16),
              const FieldLabel("Student's note"),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TaskColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  submission.note.isEmpty
                      ? 'No note was added.'
                      : submission.note,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: TaskColors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const FieldLabel('Your feedback'),
              TextField(
                controller: _feedback,
                minLines: 3,
                maxLines: 5,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                decoration: taskInputDecoration(
                  'Write feedback for the student...',
                ),
              ),
              const SizedBox(height: 8),
              TaskPrimaryButton(
                label: submission.isReviewed
                    ? 'Update Review'
                    : 'Mark as Reviewed',
                onPressed: () => Navigator.pop(context, _feedback.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
