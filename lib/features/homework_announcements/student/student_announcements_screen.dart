import 'package:flutter/material.dart';

import '../models/announcement.dart';
import '../services/student_homework_service.dart';
import '../widgets/task_widgets.dart';

/// "2h ago", "1d ago", or a short date for older items.
String _timeAgo(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return shortDate(d);
}

/// "10:24 AM"
String _clock(DateTime d) {
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  return '$hour12:$minute ${d.hour < 12 ? 'AM' : 'PM'}';
}

bool _isNew(Announcement a) =>
    DateTime.now().difference(a.publishAt).inHours < 24;

({Color fg, Color bg}) _priorityColors(AnnouncementPriority p) => switch (p) {
  AnnouncementPriority.urgent => (
    fg: TaskColors.red,
    bg: TaskColors.redSoft,
  ),
  AnnouncementPriority.important => (
    fg: TaskColors.amber,
    bg: TaskColors.amberSoft,
  ),
  AnnouncementPriority.normal => (
    fg: TaskColors.blue,
    bg: TaskColors.blueSoft,
  ),
};

/// Announcements sent to the student's class or to all students.
class StudentAnnouncementsScreen extends StatefulWidget {
  const StudentAnnouncementsScreen({super.key});

  @override
  State<StudentAnnouncementsScreen> createState() =>
      _StudentAnnouncementsScreenState();
}

class _StudentAnnouncementsScreenState
    extends State<StudentAnnouncementsScreen> {
  final _service = StudentHomeworkService();
  late final Stream<List<Announcement>> _stream = _service
      .watchMyAnnouncements();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaskColors.background,
      appBar: taskAppBar('Announcements'),
      body: SafeArea(
        child: StreamBuilder<List<Announcement>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _Message(
                friendlyError(
                  snapshot.error!,
                  'Could not load announcements. Please try again.',
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            // Scheduled announcements stay hidden until their publish time.
            final items = snapshot.data!.where((a) => !a.isScheduled).toList();
            if (items.isEmpty) {
              return const _Message('No announcements yet.');
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Latest Updates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: TaskColors.ink,
                      ),
                    ),
                  ),
                  for (final a in items) _row(a),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _row(Announcement a) {
    final colors = _priorityColors(a.priority);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TaskColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentAnnouncementDetailScreen(announcement: a),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  a.priority == AnnouncementPriority.urgent
                      ? Icons.priority_high_rounded
                      : Icons.campaign_outlined,
                  color: colors.fg,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            a.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: TaskColors.ink,
                            ),
                          ),
                        ),
                        if (_isNew(a))
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: TaskColors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TaskColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _timeAgo(a.publishAt),
                style: const TextStyle(fontSize: 11, color: TaskColors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full announcement page, based on the Figma "announcement-detail" frame.
class StudentAnnouncementDetailScreen extends StatelessWidget {
  final Announcement announcement;
  const StudentAnnouncementDetailScreen({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    final colors = _priorityColors(a.priority);
    return Scaffold(
      backgroundColor: TaskColors.background,
      appBar: taskAppBar('Announcement'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      a.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: TaskColors.ink,
                      ),
                    ),
                  ),
                  if (_isNew(a)) ...[
                    const SizedBox(width: 8),
                    const TaskChip(text: 'New'),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TaskChip(text: a.audience),
                  if (a.priority != AnnouncementPriority.normal)
                    TaskChip(
                      text: a.priority == AnnouncementPriority.urgent
                          ? 'Urgent'
                          : 'Important',
                      background: colors.bg,
                      foreground: colors.fg,
                    ),
                  Text(
                    '${longDate(a.publishAt)} • ${_clock(a.publishAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: TaskColors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: TaskColors.border),
                ),
                child: Text(
                  a.body,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: TaskColors.ink,
                  ),
                ),
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