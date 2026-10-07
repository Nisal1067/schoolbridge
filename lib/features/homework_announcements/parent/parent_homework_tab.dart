import 'package:flutter/material.dart';

import '../models/student_homework.dart';
import '../services/parent_homework_service.dart';
import '../services/student_homework_service.dart' show friendlyError;
import '../student/student_homework_screen.dart' show subjectIcon;
import '../widgets/task_widgets.dart';
import 'parent_common.dart';
import 'parent_homework_detail_screen.dart';

/// Parent "Homework" tab: pick a child, see how their homework is going.
class ParentHomeworkTab extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  const ParentHomeworkTab({super.key, required this.students});

  @override
  State<ParentHomeworkTab> createState() => _ParentHomeworkTabState();
}

class _ParentHomeworkTabState extends State<ParentHomeworkTab> {
  final _service = ParentHomeworkService();
  late Stream<List<StudentHomework>> _stream;
  int _selected = 0;
  int _filter = 0; // 0 all, 1 pending, 2 overdue, 3 completed

  Map<String, dynamic> get _child => widget.students[_selected];

  @override
  void initState() {
    super.initState();
    _stream = _service.watchChildHomework(_child);
  }

  void _selectChild(int index) {
    if (index == _selected) return;
    setState(() {
      _selected = index;
      _filter = 0;
      _stream = _service.watchChildHomework(_child);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.students.length > 1) ...[
            ChildSelector(
              students: widget.students,
              selected: _selected,
              onChanged: _selectChild,
            ),
            const SizedBox(height: 14),
          ],
          StreamBuilder<List<StudentHomework>>(
            // New State per child so the previous child's list never lingers.
            key: ValueKey(_child['id']),
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return ParentMessage(
                  friendlyError(
                    snapshot.error!,
                    'Could not load homework. Please try again.',
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
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TaskColors.border),
      ),
      child: child,
    );
  }

  bool _matches(StudentHomework item) => switch (_filter) {
    1 => item.status == HomeworkStatus.pending,
    2 => item.status == HomeworkStatus.overdue,
    3 => item.isDone,
    _ => true,
  };

  Widget _content(List<StudentHomework> items) {
    final name = firstName(_child);
    final total = items.length;
    final done = items.where((i) => i.isDone).length;
    final pending = items
        .where((i) => i.status == HomeworkStatus.pending)
        .length;
    final overdue = items
        .where((i) => i.status == HomeworkStatus.overdue)
        .length;
    final soon = items.where(isDueSoon).length;
    final progress = total == 0 ? 0.0 : done / total;
    final percent = (progress * 100).round();
    final visible = items.where(_matches).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _card(
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: TaskColors.blueSoft,
                child: Text(
                  initialOf(_child),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: TaskColors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _child['name'] as String? ?? 'Student',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: TaskColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      total == 0
                          ? 'No homework assigned yet'
                          : 'Homework: $done of $total done',
                      style: const TextStyle(
                        fontSize: 13,
                        color: TaskColors.grey,
                      ),
                    ),
                    if (total > 0) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: TaskColors.blueSoft,
                          color: TaskColors.blue,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (total > 0) ...[
                const SizedBox(width: 12),
                TaskChip(
                  text: '$percent%',
                  background: TaskColors.greenSoft,
                  foreground: TaskColors.green,
                ),
              ],
            ],
          ),
        ),
        if (overdue > 0 || soon > 0) ...[
          const SizedBox(height: 12),
          _attention(name: name, overdue: overdue, soon: soon),
        ],
        const SizedBox(height: 16),
        FilterChips(
          labels: [
            'All ($total)',
            'Pending ($pending)',
            'Overdue ($overdue)',
            'Completed ($done)',
          ],
          selected: _filter,
          onChanged: (i) => setState(() => _filter = i),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const ParentMessage('Your child has no homework right now.')
        else if (visible.isEmpty)
          const ParentMessage('No homework in this list.')
        else
          for (final item in visible) _tile(item),
      ],
    );
  }

  Widget _attention({
    required String name,
    required int overdue,
    required int soon,
  }) {
    final lines = <String>[
      if (overdue > 0)
        '$name has $overdue overdue '
            '${overdue == 1 ? 'assignment' : 'assignments'}.',
      if (soon > 0)
        '$soon ${soon == 1 ? 'assignment is' : 'assignments are'} '
            'due today or tomorrow.',
    ];
    final urgent = overdue > 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: urgent ? TaskColors.redSoft : TaskColors.amberSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            urgent ? Icons.error_outline : Icons.schedule,
            color: urgent ? TaskColors.red : TaskColors.amber,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Needs attention',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: TaskColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                for (final line in lines)
                  Text(
                    line,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: TaskColors.ink,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(StudentHomework item) {
    final h = item.homework;
    final style = homeworkStatusStyle(item.status);
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
            builder: (_) =>
                ParentHomeworkDetailScreen(homeworkId: h.id!, child: _child),
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
                      '${h.subject} • Due ${shortDate(h.dueDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TaskColors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      homeworkDueText(item),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: homeworkDueColor(item),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TaskChip(
                text: style.label,
                background: style.bg,
                foreground: style.fg,
              ),
              const Icon(Icons.chevron_right, color: TaskColors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
