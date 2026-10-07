import 'package:flutter/material.dart';

import '../models/announcement.dart';
import '../services/parent_homework_service.dart';
import '../services/student_homework_service.dart' show friendlyError;
import '../student/student_announcements_screen.dart'
    show StudentAnnouncementDetailScreen;
import '../widgets/task_widgets.dart';
import 'parent_common.dart';

/// Parent "Announcements" tab: updates sent to parents, to all students, or
/// to any of the parent's children's classes.
class ParentAnnouncementsTab extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  const ParentAnnouncementsTab({super.key, required this.students});

  @override
  State<ParentAnnouncementsTab> createState() => _ParentAnnouncementsTabState();
}

class _ParentAnnouncementsTabState extends State<ParentAnnouncementsTab> {
  final _service = ParentHomeworkService();
  late final Stream<List<Announcement>> _stream = _service.watchAnnouncements(
    widget.students,
  );
  final _searchController = TextEditingController();
  String _query = '';
  int _filter = 0; // 0 all, 1 important, 2 class, 3 school

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(Announcement a) {
    final passesFilter = switch (_filter) {
      1 => a.priority != AnnouncementPriority.normal,
      2 => a.audienceType == 'class',
      3 => a.audienceType != 'class',
      _ => true,
    };
    if (!passesFilter) return false;
    if (_query.isEmpty) return true;
    return a.title.toLowerCase().contains(_query) ||
        a.body.toLowerCase().contains(_query) ||
        a.audience.toLowerCase().contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: taskInputDecoration('Search announcements').copyWith(
              prefixIcon: const Icon(Icons.search, color: TaskColors.grey),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, color: TaskColors.grey),
                      onPressed: () => setState(() {
                        _query = '';
                        _searchController.clear();
                      }),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          FilterChips(
            labels: const ['All', 'Important', 'Class', 'School'],
            selected: _filter,
            onChanged: (i) => setState(() => _filter = i),
          ),
          const SizedBox(height: 14),
          StreamBuilder<List<Announcement>>(
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ParentMessage(
                  friendlyError(
                    snapshot.error!,
                    'Could not load announcements. Please try again.',
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              // Scheduled announcements stay hidden until their publish time.
              final published = snapshot.data!
                  .where((a) => !a.isScheduled)
                  .toList();
              if (published.isEmpty) {
                return const ParentMessage('No announcements yet.');
              }
              final items = published.where(_matches).toList();
              if (items.isEmpty) {
                return const ParentMessage(
                  'No announcements match your search.',
                );
              }
              return Column(children: [for (final a in items) _row(a)]);
            },
          ),
        ],
      ),
    );
  }

  Widget _row(Announcement a) {
    final colors = priorityColors(a.priority);
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        if (isNewAnnouncement(a))
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: TaskColors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        TaskChip(text: a.audience),
                        if (a.priority == AnnouncementPriority.important)
                          const TaskChip(
                            text: 'Important',
                            background: TaskColors.amberSoft,
                            foreground: TaskColors.amber,
                          ),
                        if (a.priority == AnnouncementPriority.urgent)
                          const TaskChip(
                            text: 'Urgent',
                            background: TaskColors.redSoft,
                            foreground: TaskColors.red,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeAgo(a.publishAt),
                style: const TextStyle(fontSize: 11, color: TaskColors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
