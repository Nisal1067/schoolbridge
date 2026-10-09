import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../attendance/services/attendance_service.dart';
import '../user_communication/teacher_chat_fab.dart';

class TeacherProfileScreen extends StatefulWidget {
  final bool isTab;

  const TeacherProfileScreen({super.key, this.isTab = false});
  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final _service = AttendanceService();
  late Future<Map<String, dynamic>> _data = _load();

  Future<Map<String, dynamic>> _load() async {
    final profile = await _service.profile();
    final classes = await _service.teacherClasses();
    return {...profile, 'assignedClasses': classes};
  }

  List<String> _subjects(dynamic value) => value is List
      ? value.map((v) => v.toString()).toList()
      : value is String && value.trim().isNotEmpty
      ? [value]
      : [];

  Widget _section(String title, Widget content, {IconData? icon}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: const Color(0xFF1E40AF)),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        if (icon != null)
          const Divider(height: 24, color: Color(0xFFF1F5F9))
        else
          const SizedBox(height: 12),
        content,
      ],
    ),
  );

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'Not provided' : value,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _chips(List<String> values) => values.isEmpty
      ? const Text(
          'Not assigned yet',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
        )
      : Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (text) => Chip(
                  label: Text(text, style: const TextStyle(fontSize: 11)),
                  backgroundColor: const Color(0xFFF3F4F6),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              )
              .toList(),
        );

  String _timeText(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${time.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  Future<Map<String, dynamic>?> _addScheduleDialog(
    List<Map<String, dynamic>> classes,
  ) async {
    final subjectController = TextEditingController();
    final roomController = TextEditingController();
    final classController = TextEditingController();
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    var day = days.first;
    final classNames = classes
        .map((item) => item['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    var selectedClass = classNames.isEmpty ? null : classNames.first;
    var start = const TimeOfDay(hour: 8, minute: 0);
    var end = const TimeOfDay(hour: 9, minute: 0);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Schedule',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: day,
                  decoration: const InputDecoration(labelText: 'Day'),
                  items: days
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (value) => setModalState(() => day = value!),
                ),
                const SizedBox(height: 12),
                if (classNames.isEmpty)
                  TextField(
                    controller: classController,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      hintText: 'e.g. Grade 10A',
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: selectedClass,
                    decoration: const InputDecoration(labelText: 'Class'),
                    items: classNames
                        .map(
                          (item) =>
                              DropdownMenuItem(value: item, child: Text(item)),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setModalState(() => selectedClass = value),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    hintText: 'e.g. Mathematics',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: start,
                          );
                          if (picked != null)
                            setModalState(() => start = picked);
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(_timeText(start)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: end,
                          );
                          if (picked != null) setModalState(() => end = picked);
                        },
                        icon: const Icon(Icons.schedule),
                        label: Text(_timeText(end)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: roomController,
                  decoration: const InputDecoration(
                    labelText: 'Room (optional)',
                    hintText: 'e.g. Room 04',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: () {
                      final className =
                          selectedClass ?? classController.text.trim();
                      if (className.isEmpty ||
                          subjectController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Select a class and enter a subject.',
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context, {
                        'day': day,
                        'className': className,
                        'subject': subjectController.text.trim(),
                        'time': '${_timeText(start)} - ${_timeText(end)}',
                        'room': roomController.text.trim(),
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Save Schedule'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    subjectController.dispose();
    roomController.dispose();
    classController.dispose();
    return result;
  }

  Future<void> _schedule(Map<String, dynamic> data) async {
    final schedule = (data['schedule'] is List)
        ? (data['schedule'] as List)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];
    final classes = (data['assignedClasses'] as List? ?? [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 440,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Full Schedule',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final item = await _addScheduleDialog(classes);
                          if (item == null || !mounted) return;
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid == null) return;
                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .update({
                                  'schedule': FieldValue.arrayUnion([item]),
                                });
                            schedule.add(item);
                            setModalState(() {});
                          } catch (error) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Could not save schedule: $error',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFF1E40AF),
                        tooltip: 'Add schedule',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: schedule.isEmpty
                        ? const Center(
                            child: Text(
                              'No schedule added yet. Tap + to add one.',
                            ),
                          )
                        : ListView(
                            children: schedule
                                .asMap()
                                .entries
                                .map(
                                  (entry) => ListTile(
                                    leading: const Icon(
                                      Icons.calendar_today_outlined,
                                      color: Color(0xFF2563EB),
                                    ),
                                    title: Text(
                                      '${entry.value['subject'] ?? 'Subject'} - ${entry.value['className'] ?? 'Class'}',
                                    ),
                                    subtitle: Text(
                                      '${entry.value['day'] ?? ''} - ${entry.value['time'] ?? ''}${(entry.value['room'] ?? '').toString().isEmpty ? '' : ' - ${entry.value['room']}'}',
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      color: const Color(0xFFEF4444),
                                      onPressed: () async {
                                        final uid = FirebaseAuth
                                            .instance
                                            .currentUser
                                            ?.uid;
                                        if (uid == null) return;
                                        schedule.removeAt(entry.key);
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(uid)
                                            .update({'schedule': schedule});
                                        setModalState(() {});
                                      },
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (mounted) setState(() => _data = _load());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    appBar: widget.isTab
        ? null
        : AppBar(
            backgroundColor: const Color(0xFFF8FAFC),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Teacher Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: 0,
              ),
            ),
          ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: () => setState(() => _data = _load()),
              child: const Text('Could not load profile. Retry'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final name = (data['name'] ?? 'Teacher').toString();
        final initials = name
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0])
            .join()
            .toUpperCase();
        final subjects = _subjects(data['subjects'] ?? data['subject']);
        final photo = (data['photoUrl'] ?? '').toString();
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                kTeacherFabClearance,
              ),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E40AF).withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: const Color(0xFFEEF2FF),
                      child: photo.isEmpty
                          ? Text(
                              initials,
                              style: const TextStyle(
                                color: Color(0xFF1E40AF),
                                fontWeight: FontWeight.w800,
                                fontSize: 26,
                              ),
                            )
                          : ClipOval(
                              child: Image.network(
                                photo,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                errorBuilder: (_, error, stack) =>
                                    Text(initials),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subjects.isEmpty
                      ? 'Teacher'
                      : '${subjects.join(' / ')} Teacher',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (data['designation'] is String &&
                    (data['designation'] as String).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        data['designation'] as String,
                        style: const TextStyle(
                          color: Color(0xFF1E40AF),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _section(
                  'Personal Details',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detail(
                        'Joined Date',
                        (data['joinedDate'] ?? '').toString(),
                      ),
                      _detail('Gender', (data['gender'] ?? '').toString()),
                      _detail('Address', (data['address'] ?? '').toString()),
                    ],
                  ),
                  icon: Icons.person_outline_rounded,
                ),
                _section(
                  'Contact Details',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detail('Email', (data['email'] ?? '').toString()),
                      _detail('Phone', (data['phone'] ?? '').toString()),
                    ],
                  ),
                  icon: Icons.contact_mail_outlined,
                ),
                _section(
                  'Specialized Subjects',
                  _chips(subjects),
                  icon: Icons.book_outlined,
                ),
                _section(
                  'Assigned Classes',
                  _chips(
                    (data['assignedClasses'] as List)
                        .map((c) => c['name'].toString())
                        .toList(),
                  ),
                  icon: Icons.class_outlined,
                ),
                const SizedBox(height: 12),
                Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E40AF).withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: () => _schedule(data),
                    icon: const Icon(Icons.calendar_month_outlined, size: 20),
                    label: const Text(
                      'Manage Schedule',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
