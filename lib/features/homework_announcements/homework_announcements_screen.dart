import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import 'models/announcement.dart';
import 'models/homework.dart';
import 'screens/add_announcement_screen.dart';
import 'screens/add_homework_screen.dart';
import 'screens/homework_detail_screen.dart';
import 'services/homework_announcement_service.dart';
import 'widgets/task_widgets.dart';

/// Teacher "Tasks" tab: Homework and Announcements lists.
///
/// Used as the body of the Tasks tab in [TeacherDashboard], so it has no
/// Scaffold or bottom navigation of its own.
class HomeworkAnnouncementsScreen extends StatefulWidget {
  /// Kept so the older generic dashboard (which passes a role) still compiles.
  final UserRole? role;

  const HomeworkAnnouncementsScreen({super.key, this.role});

  @override
  State<HomeworkAnnouncementsScreen> createState() =>
      _HomeworkAnnouncementsScreenState();
}

class _HomeworkAnnouncementsScreenState
    extends State<HomeworkAnnouncementsScreen> {
  final _service = HomeworkAnnouncementService();
  // Not final: a fresh stream is made whenever the tab changes, because a
  // stream from the service can only be listened to once.
  Stream<List<Homework>> _homework = const Stream.empty();
  Stream<List<Announcement>> _announcements = const Stream.empty();
  final _searchController = TextEditingController();
  String _query = '';
  int _tab = 0;
  int _homeworkFilter = 0; // 0 all, 1 active, 2 closed
  int _announcementFilter = 0; // 0 all, 1 published, 2 scheduled

  @override
  void initState() {
    super.initState();
    _resetStreams();
  }

  void _resetStreams() {
    _homework = _service.watchHomework();
    _announcements = _service.watchAnnouncements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addHomework() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AddHomeworkScreen()),
  );

  Future<void> _addAnnouncement() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AddAnnouncementScreen()),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 84),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TaskTabs(
                    labels: const ['Homework', 'Announcements'],
                    selected: _tab,
                    onChanged: (i) => setState(() {
                      _tab = i;
                      _query = '';
                      _searchController.clear();
                      _resetStreams();
                    }),
                  ),
                  const SizedBox(height: 14),
                  DashedBox(
                    onTap: _tab == 0 ? _addHomework : _addAnnouncement,
                    child: Text(
                      _tab == 0 ? '+ Add Homework' : '+ Add Announcement',
                      style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _searchField(),
                  const SizedBox(height: 12),
                  _filterRow(),
                  const SizedBox(height: 16),
                  if (_tab == 0) _homeworkList() else _announcementList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _searchField() {
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
      decoration:
          taskInputDecoration(
            _tab == 0 ? 'Search homework' : 'Search announcements',
          ).copyWith(
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
    );
  }

  Widget _filterRow() {
    final labels = _tab == 0
        ? const ['All', 'Active', 'Closed']
        : const ['All', 'Published', 'Scheduled'];
    final selected = _tab == 0 ? _homeworkFilter : _announcementFilter;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(labels[i]),
                selected: selected == i,
                showCheckmark: false,
                onSelected: (_) => setState(() {
                  if (_tab == 0) {
                    _homeworkFilter = i;
                  } else {
                    _announcementFilter = i;
                  }
                }),
                selectedColor: const Color(0xFF1E40AF),
                backgroundColor: Colors.white,
                side: BorderSide(color: selected == i ? const Color(0xFF1E40AF) : const Color(0xFFE2E8F0)),
                labelStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: selected == i ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Homework

  Widget _homeworkList() {
    return StreamBuilder<List<Homework>>(
      stream: _homework,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _Message('Could not load homework. Please try again.');
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final all = snapshot.data!;
        if (all.isEmpty) {
          return const _Message('No homework assigned yet.');
        }
        final items = all.where((h) {
          if (_homeworkFilter == 1 && !h.isActive) return false;
          if (_homeworkFilter == 2 && h.isActive) return false;
          if (_query.isEmpty) return true;
          return h.title.toLowerCase().contains(_query) ||
              h.className.toLowerCase().contains(_query) ||
              h.subject.toLowerCase().contains(_query);
        }).toList();
        if (items.isEmpty) {
          return const _Message('No homework matches your search.');
        }
        return Column(
          children: [for (final item in items) _HomeworkCard(homework: item)],
        );
      },
    );
  }

  // ----------------------------------------------------------- Announcements

  Widget _announcementList() {
    return StreamBuilder<List<Announcement>>(
      stream: _announcements,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _Message(
            'Could not load announcements. Please try again.',
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final all = snapshot.data!;
        if (all.isEmpty) {
          return const _Message('No announcements yet.');
        }
        final items = all.where((a) {
          if (_announcementFilter == 1 && a.isScheduled) return false;
          if (_announcementFilter == 2 && !a.isScheduled) return false;
          if (_query.isEmpty) return true;
          return a.title.toLowerCase().contains(_query) ||
              a.body.toLowerCase().contains(_query) ||
              a.audience.toLowerCase().contains(_query);
        }).toList();
        if (items.isEmpty) {
          return const _Message('No announcements match your search.');
        }
        return Column(
          children: [
            for (final item in items)
              _AnnouncementCard(
                announcement: item,
                onTap: () => _showAnnouncement(item),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showAnnouncement(Announcement a) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TaskChip(text: a.audience),
                  const Spacer(),
                  Text(
                    a.isScheduled
                        ? 'Scheduled · ${shortDate(a.publishAt)}'
                        : relativeDay(a.publishAt),
                    style: const TextStyle(
                      color: TaskColors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                a.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: TaskColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    a.body,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.45,
                      color: TaskColors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext, 'delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TaskColors.red,
                          side: const BorderSide(color: TaskColors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext, 'edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TaskColors.blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'edit') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddAnnouncementScreen(existing: a)),
      );
      return;
    }
    try {
      await _service.deleteAnnouncement(a.id!);
      if (mounted) showTaskSnack(context, 'Announcement deleted.');
    } catch (_) {
      if (mounted) showTaskSnack(context, 'Could not delete announcement.');
    }
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: TaskColors.grey, fontSize: 15),
        ),
      ),
    );
  }
}

class _HomeworkCard extends StatelessWidget {
  final Homework homework;
  const _HomeworkCard({required this.homework});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HomeworkDetailScreen(homeworkId: homework.id!),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: TaskColors.blueSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_book_outlined, color: Color(0xFF1E40AF)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homework.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: 0),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            homework.className,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: TaskColors.grey,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '•',
                            style: TextStyle(
                              fontSize: 12,
                              color: TaskColors.grey,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: TaskColors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Due ${shortDate(homework.dueDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: TaskColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.article_outlined, color: TaskColors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onTap;
  const _AnnouncementCard({required this.announcement, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TaskChip(text: a.audience),
                  if (a.priority == AnnouncementPriority.important) ...[
                    const SizedBox(width: 6),
                    const TaskChip(
                      text: 'Important',
                      background: TaskColors.amberSoft,
                      foreground: TaskColors.amber,
                    ),
                  ],
                  if (a.priority == AnnouncementPriority.urgent) ...[
                    const SizedBox(width: 6),
                    const TaskChip(
                      text: 'Urgent',
                      background: TaskColors.redSoft,
                      foreground: TaskColors.red,
                    ),
                  ],
                  const Spacer(),
                  Text(
                    a.isScheduled
                        ? 'Scheduled · ${shortDate(a.publishAt)}'
                        : relativeDay(a.publishAt),
                    style: const TextStyle(
                      fontSize: 13,
                      color: TaskColors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                a.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: TaskColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                a.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: TaskColors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
