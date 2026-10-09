import 'package:flutter/material.dart';

import '../attendance/services/attendance_service.dart';
import '../user_communication/teacher_chat_fab.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});
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
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.03),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(color: const Color(0xFFF1F5F9)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF1E40AF)),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
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
    padding: const EdgeInsets.only(bottom: 6),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          TextSpan(
            text: value.isEmpty ? 'Not provided' : value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
      style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
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

  void _schedule(Map<String, dynamic> data) {
    final schedule = data['schedule'] is List ? data['schedule'] as List : [];
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Full Schedule',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: schedule.isEmpty
                      ? const Center(child: Text('No schedule added yet.'))
                      : ListView(
                          children: schedule
                              .map(
                                (item) => ListTile(
                                  leading: const Icon(
                                    Icons.calendar_today_outlined,
                                    color: Color(0xFF2563EB),
                                  ),
                                  title: Text(
                                    item is Map
                                        ? '${item['subject'] ?? ''}'
                                        : item.toString(),
                                  ),
                                  subtitle: item is Map
                                      ? Text(
                                          '${item['day'] ?? ''} ${item['time'] ?? ''} ${item['className'] ?? ''}',
                                        )
                                      : null,
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
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    appBar: AppBar(
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
                  'Personal Info',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detail(
                        'ID Number',
                        (data['employeeId'] ?? data['uid']).toString(),
                      ),
                      _detail(
                        'Joined Date',
                        (data['joinedDate'] ?? '').toString(),
                      ),
                    ],
                  ),
                  icon: Icons.badge_outlined,
                ),
                _section(
                  'Contact Info',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detail('Email', (data['email'] ?? '').toString()),
                      _detail('Phone Number', (data['phone'] ?? '').toString()),
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
                      'View Full Schedule',
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
