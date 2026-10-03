import 'package:flutter/material.dart';

import 'add_attendance_screen.dart';
import 'services/attendance_service.dart';
import 'models/attendance_record.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

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
      backgroundColor: const Color(0xFFF5F6F8),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Color(0xFF151B2B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Attendance',
          style: TextStyle(
            color: Color(0xFF151B2B),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF151B2B),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (classes.data!.length > 1)
                    DropdownButton<int>(
                      value: _selected,
                      isExpanded: true,
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
                  // CLASS INFORMATION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFFE3EEFF),
                          child: Icon(
                            Icons.groups_outlined,
                            color: Color(0xFF2F67EA),
                          ),
                        ),

                        SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_classroom!['name']}',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF151B2B),
                                ),
                              ),
                              SizedBox(height: 3),
                              FutureBuilder(
                                future: _roster,
                                builder: (context, roster) => Text(
                                  roster.hasError
                                      ? 'Could not load student count'
                                      : roster.hasData
                                      ? '${roster.data!.length} Students'
                                      : 'Loading students...',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9297A1),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ADD ATTENDANCE BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _edit([]),
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Add Attendance',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2F67EA),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Attendance Records',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF151B2B),
                    ),
                  ),

                  const SizedBox(height: 12),

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
                        return const Text('No attendance recorded yet.');
                      }
                      return Column(
                        children: groups.entries.map((entry) {
                          final stats = AttendanceRecord.summary(entry.value);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              children: [
                                _attendanceRecord(
                                  context,
                                  date: entry.key,
                                  present: stats['present']!,
                                  absent: stats['absent']!,
                                  late: stats['late']!,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      tooltip: 'Edit attendance',
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: _deleting
                                          ? null
                                          : () => _edit(entry.value),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete attendance',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: _deleting
                                          ? null
                                          : () => _delete(entry.value),
                                    ),
                                  ],
                                ),
                              ],
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

  Widget _attendanceRecord(
    BuildContext context, {
    required String date,
    required int present,
    required int absent,
    required int late,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE3EEFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF2F67EA),
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF151B2B),
                  ),
                ),

                const SizedBox(height: 5),

                Wrap(
                  spacing: 10,
                  children: [
                    Text(
                      'P: $present',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF25A875),
                      ),
                    ),
                    Text(
                      'A: $absent',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFE44F5A),
                      ),
                    ),
                    Text(
                      'L: $late',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFD69A17),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Icon(Icons.chevron_right, color: Color(0xFF9297A1)),
        ],
      ),
    );
  }
}
