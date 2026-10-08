import 'package:flutter/material.dart';

import '../models/attachment.dart';
import '../models/homework.dart';
import '../models/submission.dart';
import '../services/student_homework_service.dart';
import '../widgets/attachment_widgets.dart';
import '../widgets/task_widgets.dart';

/// Student view of one assignment: instructions, submit and teacher feedback.
class StudentHomeworkDetailScreen extends StatefulWidget {
  final String homeworkId;
  const StudentHomeworkDetailScreen({super.key, required this.homeworkId});

  @override
  State<StudentHomeworkDetailScreen> createState() =>
      _StudentHomeworkDetailScreenState();
}

class _StudentHomeworkDetailScreenState
    extends State<StudentHomeworkDetailScreen> {
  final _service = StudentHomeworkService();
  late final Stream<Homework?> _homework = _service.watchHomework(
    widget.homeworkId,
  );
  late final Stream<Submission?> _submission = _service.watchMySubmission(
    widget.homeworkId,
  );
  final _noteController = TextEditingController();
  bool _noteLoaded = false;
  bool _saving = false;

  /// Files already handed in that the student keeps, and files chosen now.
  List<Attachment> _keepFiles = [];
  List<PickedAttachment> _newFiles = [];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

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
              return const _Message('Could not load this homework.');
            }
            if (hwSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final homework = hwSnapshot.data;
            if (homework == null) {
              return const _Message('This homework is no longer available.');
            }
            return StreamBuilder<Submission?>(
              stream: _submission,
              builder: (context, subSnapshot) {
                if (subSnapshot.hasError) {
                  return const _Message('Could not load your submission.');
                }
                if (subSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final submission = subSnapshot.data;
                if (!_noteLoaded) {
                  _noteController.text = submission?.note ?? '';
                  _keepFiles = [...?submission?.attachments];
                  _noteLoaded = true;
                }
                return _content(homework, submission);
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

  Widget _content(Homework h, Submission? submission) {
    final reviewed = submission?.isReviewed ?? false;

    late final String statusText;
    late final Color statusBg;
    late final Color statusFg;
    if (submission == null) {
      if (h.isActive) {
        statusText = 'Pending';
        statusBg = TaskColors.amberSoft;
        statusFg = TaskColors.amber;
      } else {
        statusText = 'Overdue';
        statusBg = TaskColors.redSoft;
        statusFg = TaskColors.red;
      }
    } else {
      statusText = reviewed ? 'Reviewed' : 'Submitted';
      statusBg = TaskColors.greenSoft;
      statusFg = TaskColors.green;
    }

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
                      text: statusText,
                      background: statusBg,
                      foreground: statusFg,
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
                if (h.className.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    h.className,
                    style: const TextStyle(
                      fontSize: 13,
                      color: TaskColors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instructions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
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
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Attachments',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                AttachmentList(attachments: h.attachments),
              ],
            ),
          ),
          if (submission != null)
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Submission',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    submission.submittedAt == null
                        ? 'Submitted'
                        : 'Submitted ${longDate(submission.submittedAt!)}'
                              '${submission.isLate(h.dueDate) ? ' (late)' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: submission.isLate(h.dueDate)
                          ? TaskColors.red
                          : TaskColors.grey,
                    ),
                  ),
                  if (submission.note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      submission.note,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: TaskColors.ink,
                      ),
                    ),
                  ],
                  // Before review the files are listed in the editor below.
                  if (reviewed) ...[
                    const SizedBox(height: 10),
                    AttachmentList(attachments: submission.attachments),
                  ],
                ],
              ),
            ),
          if (reviewed)
            _card(
              color: TaskColors.greenSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Teacher Feedback',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    submission!.feedback.isEmpty
                        ? 'Your teacher reviewed this homework.'
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
          if (!reviewed) ...[
            const SizedBox(height: 4),
            const FieldLabel('Note to teacher (optional)'),
            TextField(
              controller: _noteController,
              minLines: 3,
              maxLines: 6,
              maxLength: 2000,
              buildCounter: (
                _, {
                required currentLength,
                required isFocused,
                required maxLength,
              }) => null,
              textCapitalization: TextCapitalization.sentences,
              decoration: taskInputDecoration(
                'Write your answer or a note for your teacher...',
              ),
            ),
            const SizedBox(height: 16),
            AttachmentPickerSection(
              saved: _keepFiles,
              pending: _newFiles,
              onSavedChanged: (files) => setState(() => _keepFiles = files),
              onPendingChanged: (files) => setState(() => _newFiles = files),
              enabled: !_saving,
              icon: Icons.cloud_upload_outlined,
              title: 'Upload Homework file',
              subtitle: 'PDF, JPG or PNG up to 10MB, max 5 files',
            ),
            const SizedBox(height: 16),
            TaskPrimaryButton(
              label: submission == null
                  ? 'Submit Homework'
                  : 'Update Submission',
              loading: _saving,
              onPressed: () => _submit(h, submission),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'This homework has been reviewed, so it can no longer be '
                'changed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: TaskColors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submit(Homework h, Submission? existing) async {
    setState(() => _saving = true);
    try {
      await _service.submitHomework(
        homework: h,
        note: _noteController.text,
        existing: existing,
        keep: _keepFiles,
        newFiles: _newFiles,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      await _showSuccess(updated: existing != null);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showTaskSnack(
        context,
        friendlyError(e, 'Could not submit homework. Please try again.'),
      );
    }
  }

  Future<void> _showSuccess({required bool updated}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: TaskColors.greenSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: TaskColors.green,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                updated ? 'Homework Updated' : 'Homework Submitted',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: TaskColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your homework was successfully submitted.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: TaskColors.grey),
              ),
              const SizedBox(height: 24),
              TaskPrimaryButton(
                label: 'Done',
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: TaskColors.grey, fontSize: 15),
        ),
      ),
    );
  }
}
