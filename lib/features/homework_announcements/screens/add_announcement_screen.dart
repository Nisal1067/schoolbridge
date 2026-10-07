import 'package:flutter/material.dart';

import '../models/announcement.dart';
import '../services/homework_announcement_service.dart';
import '../widgets/task_widgets.dart';

class _AudienceOption {
  final String label;
  final String type; // all_students | parents | teachers | class
  final String classId;
  const _AudienceOption(this.label, this.type, [this.classId = '']);

  @override
  bool operator ==(Object other) =>
      other is _AudienceOption &&
      other.type == type &&
      other.classId == classId;

  @override
  int get hashCode => Object.hash(type, classId);
}

enum _Schedule { keep, now, tomorrow, nextMonday }

/// "Add Announcement" form. Pass [existing] to edit an announcement instead.
class AddAnnouncementScreen extends StatefulWidget {
  final Announcement? existing;
  const AddAnnouncementScreen({super.key, this.existing});

  @override
  State<AddAnnouncementScreen> createState() => _AddAnnouncementScreenState();
}

class _AddAnnouncementScreenState extends State<AddAnnouncementScreen> {
  final _service = HomeworkAnnouncementService();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  List<_AudienceOption> _audiences = const [
    _AudienceOption('All Students', 'all_students'),
    _AudienceOption('Parents', 'parents'),
    _AudienceOption('Teachers', 'teachers'),
  ];
  _AudienceOption? _audience;
  AnnouncementPriority _priority = AnnouncementPriority.normal;
  late _Schedule _schedule = widget.existing == null
      ? _Schedule.now
      : _Schedule.keep;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _audience = _audiences.first;
    final existing = widget.existing;
    if (existing != null) {
      _titleController.text = existing.title;
      _bodyController.text = existing.body;
      _priority = existing.priority;
      _audience = _AudienceOption(
        existing.audience,
        existing.audienceType,
        existing.classId,
      );
      _audiences = [
        if (!_audiences.contains(_audience)) _audience!,
        ..._audiences,
      ];
    }
    _loadClassAudiences();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  /// Adds one audience per class the teacher teaches (e.g. "Grade 10A").
  Future<void> _loadClassAudiences() async {
    try {
      final classes = await _service.teacherClasses();
      classes.sort(
        (a, b) =>
            (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''),
      );
      if (!mounted) return;
      setState(() {
        final current = _audience;
        _audiences = [
          ..._audiences,
          for (final c in classes)
            if (!_audiences.contains(
              _AudienceOption('${c['name']}', 'class', c['id'] as String),
            ))
              _AudienceOption('${c['name']}', 'class', c['id'] as String),
        ];
        _audience = current != null && _audiences.contains(current)
            ? current
            : _audiences.first;
      });
    } catch (_) {
      // The three general audiences still work without the class list.
    }
  }

  String _scheduleLabel(_Schedule s) => switch (s) {
    _Schedule.keep => 'Keep current time',
    _Schedule.now => 'Send Now',
    _Schedule.tomorrow => 'Tomorrow, 8:00 AM',
    _Schedule.nextMonday => 'Next Monday, 8:00 AM',
  };

  DateTime _publishTime() {
    final now = DateTime.now();
    switch (_schedule) {
      case _Schedule.keep:
        return widget.existing?.publishAt ?? now;
      case _Schedule.now:
        return now;
      case _Schedule.tomorrow:
        final d = now.add(const Duration(days: 1));
        return DateTime(d.year, d.month, d.day, 8);
      case _Schedule.nextMonday:
        var d = now.add(const Duration(days: 1));
        while (d.weekday != DateTime.monday) {
          d = d.add(const Duration(days: 1));
        }
        return DateTime(d.year, d.month, d.day, 8);
    }
  }

  Future<void> _publish() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty) {
      showTaskSnack(context, 'Enter an announcement title.');
      return;
    }
    if (body.isEmpty) {
      showTaskSnack(context, 'Enter the message body.');
      return;
    }
    final audience = _audience;
    if (audience == null) return;

    setState(() => _saving = true);
    try {
      final existing = widget.existing;
      if (existing != null) {
        await _service.updateAnnouncement(
          existing,
          title: title,
          body: body,
          audience: audience.label,
          audienceType: audience.type,
          classId: audience.classId,
          priority: _priority,
          publishAt: _publishTime(),
        );
      } else {
        await _service.createAnnouncement(
          title: title,
          body: body,
          audience: audience.label,
          audienceType: audience.type,
          classId: audience.classId,
          priority: _priority,
          publishAt: _publishTime(),
        );
      }
      if (!mounted) return;
      showTaskSnack(
        context,
        _editing
            ? 'Announcement updated.'
            : _schedule == _Schedule.now
            ? 'Announcement published.'
            : 'Announcement scheduled.',
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showTaskSnack(context, 'Could not publish. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaskColors.background,
      appBar: taskAppBar(_editing ? 'Edit Announcement' : 'Add Announcement'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const FieldLabel('Announcement Title'),
            TextField(
              controller: _titleController,
              maxLength: 120,
              buildCounter: (
                _, {
                required currentLength,
                required isFocused,
                required maxLength,
              }) => null,
              textCapitalization: TextCapitalization.sentences,
              decoration: taskInputDecoration('e.g. End of Year Exam Schedule'),
            ),
            const SizedBox(height: 16),
            const FieldLabel('Target Audience'),
            TaskDropdown<_AudienceOption>(
              value: _audience,
              items: [
                for (final a in _audiences)
                  DropdownMenuItem(value: a, child: Text(a.label)),
              ],
              onChanged: (v) => setState(() => _audience = v),
            ),
            const SizedBox(height: 16),
            const FieldLabel('Priority Level'),
            Row(
              children: [
                _priorityChip(
                  AnnouncementPriority.normal,
                  'Normal',
                  dot: TaskColors.grey,
                  tint: Colors.white,
                  border: TaskColors.border,
                  text: TaskColors.grey,
                ),
                const SizedBox(width: 8),
                _priorityChip(
                  AnnouncementPriority.important,
                  'Important',
                  dot: TaskColors.amber,
                  tint: TaskColors.amberSoft,
                  border: TaskColors.amber,
                  text: const Color(0xFFB45309),
                ),
                const SizedBox(width: 8),
                _priorityChip(
                  AnnouncementPriority.urgent,
                  'Urgent',
                  dot: TaskColors.red,
                  tint: TaskColors.redSoft,
                  border: TaskColors.red,
                  text: TaskColors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const FieldLabel('Message Body'),
            TextField(
              controller: _bodyController,
              minLines: 6,
              maxLines: 10,
              maxLength: 2000,
              buildCounter: (
                _, {
                required currentLength,
                required isFocused,
                required maxLength,
              }) => null,
              textCapitalization: TextCapitalization.sentences,
              decoration: taskInputDecoration(
                'Type the full broadcast message details here...',
              ),
            ),
            const SizedBox(height: 16),
            const FieldLabel('Publish Schedule'),
            TaskDropdown<_Schedule>(
              value: _schedule,
              items: [
                for (final s in _Schedule.values)
                  if (s != _Schedule.keep || _editing)
                    DropdownMenuItem(value: s, child: Text(_scheduleLabel(s))),
              ],
              onChanged: (v) => setState(() => _schedule = v!),
            ),
            const SizedBox(height: 32),
            TaskPrimaryButton(
              label: _editing ? 'Save Changes' : 'Publish Announcement',
              loading: _saving,
              onPressed: _publish,
            ),
          ],
        ),
      ),
    );
  }

  Widget _priorityChip(
    AnnouncementPriority value,
    String label, {
    required Color dot,
    required Color tint,
    required Color border,
    required Color text,
  }) {
    final selected = _priority == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? tint : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? border : TaskColors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? text : TaskColors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
