import 'package:flutter/material.dart';

import '../../dashboards/screens/teacher_dashboard.dart';

import 'widgets/attendance_navigation.dart';

import 'add_attendance_screen.dart';
import 'services/attendance_service.dart';
import 'models/attendance_record.dart';
import '../user_communication/teacher_chat_fab.dart';

class AttendanceScreen extends StatefulWidget {
  /// Set to false when the screen is used as a tab (no screen to go back to).
  final bool showBackButton;

  const AttendanceScreen({super.key, this.showBackButton = true});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _service = AttendanceService();
  late Future<List<Map<String, dynamic>>> _classes = _service.teacherClasses();
  int _selected = 0;
  Future<List<Map<String, dynamic>>>? _roster;
  Stream<List<AttendanceRecord>>? _records;
  Map<String, dynamic>? _classroom;
  bool _deleting = false;

  Future<void> _edit(List<AttendanceRecord> existing) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddAttendanceScreen(classroom: _classroom, existing: existing),
      ),
    );
  }

  Future<void> _delete(List<AttendanceRecord> records) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete attendance?'),
        content: const Text('Delete all marks for this class on this date?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await _service.deleteAttendance(records);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete attendance.')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      bottomNavigationBar: AttendanceNavigation(
        teacher: true,
        teacherLayout: true,
      ),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Color(0xFF17212F),
                ),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeacherDashboard(),
                      ),
                    );
                  }
                },
              )
            : null,
        title: const Text(
          'Manage Attendance',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _classes,
        builder: (context, classes) {
          if (classes.hasError) {
            return Center(
              child: TextButton(
                onPressed: () =>
                    setState(() => _classes = _service.teacherClasses()),
                child: const Text('Could not load classes. Retry'),
              ),
            );
          }
          if (!classes.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (classes.data!.isEmpty) {
            return const Center(
              child: Text('No class assigned to your account.'),
            );
          }
          _classroom = classes.data![_selected];
          _roster ??= _service.studentsForClass(_classroom!);
          _records ??= _service.classRecords(_classroom!);
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                kTeacherFabClearance,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (classes.data!.length > 1)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selected,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Color(0xFF64748B),
                          ),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                          items: List.generate(
                            classes.data!.length,
                            (i) => DropdownMenuItem(
                              value: i,
                              child: Text(classes.data![i]['name'] as String),
                            ),
                          ),
                          onChanged: (i) => setState(() {
                            _selected = i!;
                            _roster = null;
                            _records = null;
                          }),
                        ),
                      ),
                    ),

                  // CLASS INFORMATION PREMIUM CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.groups_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_classroom!['name']}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              FutureBuilder(
                                future: _roster,
                                builder: (context, roster) => Text(
                                  roster.hasError
                                      ? 'Error loading students'
                                      : roster.hasData
                                      ? '${roster.data!.length} Active Students'
                                      : 'Loading students...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ADD ATTENDANCE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _deleting ? null : () => _edit([]),
                      icon: const Icon(Icons.add_circle_outline, size: 22),
                      label: const Text(
                        'Record New Attendance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF2563EB)
                            .withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  Row(
                    children: [
                      const Icon(
                        Icons.history_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Recent Records',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  StreamBuilder<List<AttendanceRecord>>(
                    key: ValueKey(_classroom!['id']),
                    stream: _records,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text(
                          'Could not load attendance. Check permissions.',
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final groups = <String, List<AttendanceRecord>>{};
                      for (final record in snapshot.data!) {
                        final key =
                            '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}-${record.date.day.toString().padLeft(2, '0')}';
                        groups.putIfAbsent(key, () => []).add(record);
                      }
                      if (groups.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 36),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_available_outlined,
                                  size: 40,
                                  color: Color(0xFF64748B),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No attendance recorded yet.',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: groups.entries.map<Widget>((entry) {
                          final stats = AttendanceRecord.summary(entry.value);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: const Color(0xFFF1F5F9),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Left Calendar Icon
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F9FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_month_rounded,
                                      color: Color(0xFF0EA5E9),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Date & Stats
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _buildStatPill(
                                              'P',
                                              stats['present']!,
                                              const Color(0xFF10B981),
                                              const Color(0xFFD1FAE5),
                                            ),
                                            _buildStatPill(
                                              'A',
                                              stats['absent']!,
                                              const Color(0xFFEF4444),
                                              const Color(0xFFFEE2E2),
                                            ),
                                            _buildStatPill(
                                              'L',
                                              stats['late']!,
                                              const Color(0xFFF59E0B),
                                              const Color(0xFFFEF3C7),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Actions
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _actionButton(
                                        icon: Icons.edit_note_rounded,
                                        color: const Color(0xFF64748B),
                                        onPressed: _deleting
                                            ? null
                                            : () => _edit(entry.value),
                                      ),
                                      _actionButton(
                                        icon: Icons.delete_outline_rounded,
                                        color: const Color(0xFFEF4444),
                                        onPressed: _deleting
                                            ? null
                                            : () => _delete(entry.value),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatPill(
    String label,
    int count,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }
}
