import 'package:flutter/material.dart';

import '../models/homework.dart';
import '../services/homework_announcement_service.dart';
import '../widgets/task_widgets.dart';

/// "Add Homework" form. Pass [existing] to edit an assignment instead.
class AddHomeworkScreen extends StatefulWidget {
  final Homework? existing;
  const AddHomeworkScreen({super.key, this.existing});

  @override
  State<AddHomeworkScreen> createState() => _AddHomeworkScreenState();
}

class _AddHomeworkScreenState extends State<AddHomeworkScreen> {
  final _service = HomeworkAnnouncementService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<Map<String, dynamic>> _classes = [];
  String? _classId;
  String _subject = kSubjects.first;
  late DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  bool _loading = true;
  bool _saving = false;
  String? _loadError;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _titleController.text = existing.title;
      _descriptionController.text = existing.description;
      _classId = existing.classId;
      _dueDate = existing.dueDate;
      _subject = kSubjects.contains(existing.subject)
          ? existing.subject
          : kSubjects.first;
    }
    _loadClasses();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadClasses() async {
    try {
      final classes = await _service.teacherClasses();
      classes.sort(
        (a, b) =>
            (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''),
      );
      if (!mounted) return;
      setState(() {
        _classes = classes;
        if (_classId == null && classes.isNotEmpty) {
          _classId = classes.first['id'] as String;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load your classes. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate.isBefore(today) ? today : _dueDate,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(today.year + 2),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showTaskSnack(context, 'Enter a homework title.');
      return;
    }
    if (title.length > 120) {
      showTaskSnack(context, 'Title must be 120 characters or fewer.');
      return;
    }
    if (_descriptionController.text.trim().length > 2000) {
      showTaskSnack(context, 'Description must be 2000 characters or fewer.');
      return;
    }
    if (_classId == null) {
      showTaskSnack(context, 'Choose a class.');
      return;
    }

    setState(() => _saving = true);
    try {
      final existing = widget.existing;
      if (existing != null) {
        await _service.updateHomework(
          existing,
          subject: _subject,
          title: title,
          description: _descriptionController.text,
          dueDate: _dueDate,
        );
      } else {
        final classroom = _classes.firstWhere((c) => c['id'] == _classId);
        await _service.createHomework(
          classroom: classroom,
          subject: _subject,
          title: title,
          description: _descriptionController.text,
          dueDate: _dueDate,
        );
      }
      if (!mounted) return;
      showTaskSnack(
        context,
        _editing ? 'Homework updated.' : 'Homework assigned.',
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showTaskSnack(context, 'Could not save homework. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaskColors.background,
      appBar: taskAppBar(_editing ? 'Edit Homework' : 'Add Homework'),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_loadError!, textAlign: TextAlign.center),
                ),
              )
            : _classes.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'You have no classes assigned yet. Contact your school.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : _form(),
      ),
    );
  }

  Widget _form() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const FieldLabel('Homework Title'),
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
          decoration: taskInputDecoration('e.g. Science Lab Report'),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('Subject'),
                  TaskDropdown<String>(
                    value: _subject,
                    items: [
                      for (final s in kSubjects)
                        DropdownMenuItem(value: s, child: Text(s)),
                    ],
                    onChanged: (v) => setState(() => _subject = v!),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FieldLabel('Grade / Class'),
                  TaskDropdown<String>(
                    value: _classId,
                    items: [
                      for (final c in _classes)
                        DropdownMenuItem(
                          value: c['id'] as String,
                          child: Text('${c['name']}'),
                        ),
                    ],
                    // The class cannot change once homework is assigned.
                    onChanged: _editing
                        ? null
                        : (v) => setState(() => _classId = v),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const FieldLabel('Description'),
        TextField(
          controller: _descriptionController,
          minLines: 4,
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
            'Describe the homework instructions, expectations and '
            'formatting rules...',
          ),
        ),
        const SizedBox(height: 16),
        const FieldLabel('Due Date'),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _pickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: TaskColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: TaskColors.grey,
                ),
                const SizedBox(width: 12),
                Text(
                  longDate(_dueDate),
                  style: const TextStyle(fontSize: 15, color: TaskColors.ink),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const FieldLabel('Attachments'),
        // Attachments need Firebase Storage, which is not in pubspec.yaml yet.
        DashedBox(
          padding: const EdgeInsets.symmetric(vertical: 22),
          fill: Colors.white,
          onTap: () => showTaskSnack(
            context,
            'Attachments are coming soon. Add instructions in the '
            'description for now.',
          ),
          child: const Column(
            children: [
              Icon(Icons.file_upload_outlined, color: TaskColors.blue),
              SizedBox(height: 8),
              Text(
                'Upload PDF or Images',
                style: TextStyle(
                  color: TaskColors.blue,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Max file size 10MB',
                style: TextStyle(color: TaskColors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        TaskPrimaryButton(
          label: _editing ? 'Save Changes' : 'Assign Homework',
          loading: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}
