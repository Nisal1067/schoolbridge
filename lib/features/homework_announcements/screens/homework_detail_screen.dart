import 'package:flutter/material.dart';

import '../models/homework.dart';
import '../models/submission.dart';
import '../services/homework_announcement_service.dart';
import '../widgets/attachment_widgets.dart';
import '../widgets/task_widgets.dart';
import 'add_homework_screen.dart';
import 'homework_dashboard_screen.dart';
import '../../user_communication/teacher_chat_fab.dart';

/// "Homework Details" page. Listens to the document so edits show instantly.
class HomeworkDetailScreen extends StatefulWidget {
  final String homeworkId;
  const HomeworkDetailScreen({super.key, required this.homeworkId});

  @override
  State<HomeworkDetailScreen> createState() => _HomeworkDetailScreenState();
}

class _HomeworkDetailScreenState extends State<HomeworkDetailScreen> {
  final _service = HomeworkAnnouncementService();
  late final Stream<Homework?> _stream = _service.watchHomeworkById(
    widget.homeworkId,
  );
  late final Stream<List<Submission>> _submissions = _service.watchSubmissions(
    widget.homeworkId,
  );
  bool _deleting = false;

  Future<void> _delete(Homework homework) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete homework?'),
        content: Text('"${homework.title}" will be removed for everyone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: TaskColors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await _service.deleteHomework(homework.id!);
      if (!mounted) return;
      showTaskSnack(context, 'Homework deleted.');
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      showTaskSnack(context, 'Could not delete homework.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaskColors.background,
      appBar: taskAppBar('Homework Details'),
      floatingActionButton: const TeacherChatFab(),
      body: SafeArea(
        child: StreamBuilder<Homework?>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Could not load this homework.'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final homework = snapshot.data;
            if (homework == null) {
              return const Center(
                child: Text('This homework is no longer available.'),
              );
            }
            return _content(homework);
          },
        ),
      ),
    );
  }

  Widget _content(Homework h) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, kTeacherFabClearance),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TaskChip(text: h.subject),
                    const Spacer(),
                    h.isActive
                        ? const TaskChip(
                            text: 'Active',
                            background: TaskColors.greenSoft,
                            foreground: TaskColors.green,
                          )
                        : const TaskChip(
                            text: 'Closed',
                            background: TaskColors.redSoft,
                            foreground: TaskColors.red,
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
                Text(
                  '${h.className}   •   Due: ${longDate(h.dueDate)}',
                  style: const TextStyle(fontSize: 14, color: TaskColors.grey),
                ),
              ],
            ),
          ),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instructions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
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
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reference Files',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                AttachmentList(attachments: h.attachments),
              ],
            ),
          ),
          StreamBuilder<List<Submission>>(
            stream: _submissions,
            builder: (context, snapshot) {
              // Counts come from the real submissions, not a stored number.
              final submitted = snapshot.data?.length ?? 0;
              final total = h.totalStudents;
              final progress = total == 0
                  ? 0.0
                  : (submitted / total).clamp(0.0, 1.0);
              final pending = (total - submitted).clamp(0, total);
              return _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Submissions Status',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$submitted / $total Submitted',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: TaskColors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: TaskColors.border,
                        color: TaskColors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '$pending Pending',
                          style: const TextStyle(
                            fontSize: 12,
                            color: TaskColors.grey,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(progress * 100).round()}% Complete',
                          style: const TextStyle(
                            fontSize: 12,
                            color: TaskColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _deleting ? null : () => _delete(h),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TaskColors.red,
                      backgroundColor: TaskColors.redSoft.withValues(
                        alpha: 0.4,
                      ),
                      side: const BorderSide(color: TaskColors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _deleting
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddHomeworkScreen(existing: h),
                            ),
                          ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TaskColors.blue,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: TaskColors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Edit Assignment',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TaskPrimaryButton(
            label: 'Homework Dashboard',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HomeworkDashboardScreen(homework: h),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TaskColors.border),
      ),
      child: child,
    );
  }
}
