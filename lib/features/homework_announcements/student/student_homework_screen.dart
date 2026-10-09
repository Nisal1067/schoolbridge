import 'package:flutter/material.dart';

import '../models/student_homework.dart';
import '../services/student_homework_service.dart';
import '../widgets/task_widgets.dart';
import '../../notifications/screens/notifications_screen.dart';
import 'student_announcements_screen.dart';
import 'student_homework_detail_screen.dart';

IconData subjectIcon(String subject) {
  switch (subject.toLowerCase()) {
    case 'mathematics':
      return Icons.calculate_outlined;
    case 'science':
      return Icons.science_outlined;
    case 'english':
      return Icons.menu_book_outlined;
    case 'history':
      return Icons.history_edu_outlined;
    case 'ict':
      return Icons.computer_outlined;
    case 'art':
      return Icons.palette_outlined;
    default:
      return Icons.assignment_outlined;
  }
}

/// Student "Homework" tab. Has its own header, so the host Scaffold should
/// hide its AppBar on this tab.
class StudentHomeworkScreen extends StatefulWidget {
  const StudentHomeworkScreen({super.key});

  @override
  State<StudentHomeworkScreen> createState() => _StudentHomeworkScreenState();
}

class _StudentHomeworkScreenState extends State<StudentHomeworkScreen> {
  final _service = StudentHomeworkService();
  late final Future<Map<String, dynamic>> _student = _service.studentRecord();
  late Stream<List<StudentHomework>> _homework;
  bool _showAnnouncements = false;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _homework = _service.watchMyHomework();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TaskColors.background,
      child: Column(
        children: [
          _header(),
          Expanded(
            child: _showAnnouncements
                ? const StudentAnnouncementsContent()
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: StreamBuilder<List<StudentHomework>>(
                      stream: _homework,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _Message(
                            friendlyError(
                              snapshot.error!,
                              'Could not load homework. Please try again.',
                              operation: 'read',
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 60),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _content(snapshot.data!);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: TaskColors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Homework',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: TaskColors.ink,
                  ),
                ),
              ),
              Material(
                color: Colors.white,
                shape: const CircleBorder(
                  side: BorderSide(color: TaskColors.border),
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const NotificationsScreen(onlyNotifications: true),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: TaskColors.blue,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionSwitcher(),
        ],
      ),
    );
  }

  Widget _sectionSwitcher() {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: TaskColors.border),
      ),
      child: Row(
        children: [
          _switcherItem('Homework', !_showAnnouncements, () {
            setState(() {
              _homework = _service.watchMyHomework();
              _showAnnouncements = false;
            });
          }),
          _switcherItem('Announcements', _showAnnouncements, () {
            setState(() => _showAnnouncements = true);
          }),
        ],
      ),
    );
  }

  Widget _switcherItem(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? TaskColors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : TaskColors.grey,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TaskColors.border),
      ),
      child: child,
    );
  }

  Widget _content(List<StudentHomework> items) {
    final total = items.length;
    final done = items.where((i) => i.isDone).length;
    final left = total - done;
    final progress = total == 0 ? 0.0 : done / total;
    final percent = (progress * 100).round();
    final visible = _showAll ? items : items.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: TaskColors.blueSoft,
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _student,
                  builder: (context, snap) {
                    final name = snap.data?['name'] as String? ?? '';
                    return Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: TaskColors.blue,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<Map<String, dynamic>>(
                      future: _student,
                      builder: (context, snap) => Text(
                        snap.data?['name'] as String? ?? 'Student',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: TaskColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Homework: $done of $total Done',
                      style: const TextStyle(
                        fontSize: 13,
                        color: TaskColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _showStats(items),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: TaskColors.blueSoft,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TaskColors.blue),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Stats',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: TaskColors.blue,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.show_chart, size: 16, color: TaskColors.blue),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      total == 0 ? 'No homework yet' : 'Keep going!',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: TaskColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      total == 0
                          ? 'Your teachers have not assigned any homework.'
                          : left == 0
                          ? 'All homework is done. Great work!'
                          : '$left homework '
                                '${left == 1 ? 'assignment' : 'assignments'} left.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: TaskColors.grey,
                      ),
                    ),
                    if (total > 0) ...[
                      const SizedBox(height: 8),
                      TaskChip(
                        text: '$percent% Completed',
                        background: TaskColors.greenSoft,
                        foreground: TaskColors.green,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 68,
                      height: 68,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 7,
                        backgroundColor: TaskColors.blueSoft,
                        color: TaskColors.blue,
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: TaskColors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(
              child: Text(
                'My Homework',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: TaskColors.ink,
                ),
              ),
            ),
            if (items.length > 4)
              GestureDetector(
                onTap: () => setState(() => _showAll = !_showAll),
                child: Text(
                  _showAll ? 'Show Less' : 'See All',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TaskColors.blue,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          const _Message('No homework to show.')
        else
          for (final item in visible) _tile(item),
        const SizedBox(height: 8),
        _focusCard(items),
      ],
    );
  }

  Widget _tile(StudentHomework item) {
    final h = item.homework;
    final (label, bg, fg) = switch (item.status) {
      HomeworkStatus.pending => (
        'Pending',
        TaskColors.amberSoft,
        TaskColors.amber,
      ),
      HomeworkStatus.overdue => ('Overdue', TaskColors.redSoft, TaskColors.red),
      HomeworkStatus.submitted => (
        'Submitted',
        TaskColors.greenSoft,
        TaskColors.green,
      ),
      HomeworkStatus.reviewed => (
        'Reviewed',
        TaskColors.greenSoft,
        TaskColors.green,
      ),
    };
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
            builder: (_) => StudentHomeworkDetailScreen(homeworkId: h.id!),
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
                  color: TaskColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(subjectIcon(h.subject), color: TaskColors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: TaskColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Due ${shortDate(h.dueDate)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: TaskColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              TaskChip(text: label, background: bg, foreground: fg),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: TaskColors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _focusCard(List<StudentHomework> items) {
    final upcoming =
        items.where((i) => !i.isDone && i.homework.isActive).toList()
          ..sort((a, b) => a.homework.dueDate.compareTo(b.homework.dueDate));
    final text = upcoming.isEmpty
        ? 'You have no upcoming deadlines. Keep up the good work!'
        : 'Your next deadline is ${upcoming.first.homework.title} '
              'on ${shortDate(upcoming.first.homework.dueDate)}.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TaskColors.blueSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stay Focused!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: TaskColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: TaskColors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              color: TaskColors.blue,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  void _showStats(List<StudentHomework> items) {
    int count(HomeworkStatus s) => items.where((i) => i.status == s).length;
    Widget stat(String label, int value, Color color, Color soft) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 22,
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

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Homework Stats',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: TaskColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  stat(
                    'Pending',
                    count(HomeworkStatus.pending),
                    TaskColors.amber,
                    TaskColors.amberSoft,
                  ),
                  const SizedBox(width: 8),
                  stat(
                    'Overdue',
                    count(HomeworkStatus.overdue),
                    TaskColors.red,
                    TaskColors.redSoft,
                  ),
                  const SizedBox(width: 8),
                  stat(
                    'Submitted',
                    count(HomeworkStatus.submitted),
                    TaskColors.blue,
                    TaskColors.blueSoft,
                  ),
                  const SizedBox(width: 8),
                  stat(
                    'Reviewed',
                    count(HomeworkStatus.reviewed),
                    TaskColors.green,
                    TaskColors.greenSoft,
                  ),
                ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
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
