import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'widgets/attendance_navigation.dart';
import 'attendance_screen.dart';

import 'models/attendance_record.dart';
import 'services/attendance_service.dart';

class AddAttendanceScreen extends StatefulWidget {
  final Map<String, dynamic>? classroom;
  final List<AttendanceRecord> existing;
  const AddAttendanceScreen({
    super.key,
    this.classroom,
    this.existing = const [],
  });

  @override
  State<AddAttendanceScreen> createState() => _AddAttendanceScreenState();
}

class _AddAttendanceScreenState extends State<AddAttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();

  bool _isSaving = false;

  void _returnToAttendance({bool saved = false}) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, saved);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AttendanceScreen()),
      );
    }
  }

  final List<Map<String, String>> students = [];
  Map<String, dynamic>? _classroom;
  bool _loading = true;
  String? _error;
  DateTime _date = DateTime.now();
  late int _term = AttendanceRecord.termForDate(_date);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final classes = widget.classroom == null
          ? await _attendanceService.teacherClasses()
          : [widget.classroom!];
      if (classes.isEmpty) {
        throw StateError('No class assigned to your account.');
      }
      _classroom = classes.first;
      final roster = await _attendanceService.studentsForClass(_classroom!);
      if (widget.existing.isNotEmpty) {
        _date = widget.existing.first.date;
        _term = widget.existing.first.term;
      }
      final statuses = {for (final r in widget.existing) r.studentId: r.status};
      students.addAll(
        roster.map((s) {
          final name = s['name'] as String;
          return {
            'id': s['id'] as String,
            'name': name,
            'initials': name
                .split(' ')
                .where((p) => p.isNotEmpty)
                .take(2)
                .map((p) => p[0])
                .join(),
            'status': statuses[s['id']] ?? '',
          };
        }),
      );
    } catch (_) {
      _error = 'Could not load your class and students. Check class assignment and permissions.';
    }
    if (mounted) setState(() => _loading = false);
  }

  // ------------------------------------------------------------
  // SAVE ATTENDANCE
  // ------------------------------------------------------------

  void _saveAttendance() {
    if (_isSaving || students.isEmpty) {
      return;
    }

    final unmarkedStudents = students
        .where((student) => student['status']!.isEmpty)
        .toList();

    // Validate whether all students are marked.
    if (unmarkedStudents.isNotEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFFF5B65),
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Please mark attendance for all students. '
            '${unmarkedStudents.length} remaining.',
          ),
        ),
      );

      return;
    }

    // Calculate attendance summary.
    final presentCount = students
        .where((student) => student['status'] == 'P')
        .length;

    final absentCount = students
        .where((student) => student['status'] == 'A')
        .length;

    final lateCount = students
        .where((student) => student['status'] == 'L')
        .length;

    _showConfirmationDialog(presentCount, absentCount, lateCount);
  }

  // ------------------------------------------------------------
  // FIRESTORE SAVE
  // ------------------------------------------------------------

  Future<void> _persistAttendance() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw Exception('User is not logged in.');
    }

    final now = _date;

    // Store only the day for attendance.
    final attendanceDate = DateTime(now.year, now.month, now.day);

    final records = students.map((student) {
      return AttendanceRecord(
        id: {
          for (final r in widget.existing) r.studentId: r.documentId,
        }[student['id']],
        studentId: student['id']!,
        studentName: student['name']!,
        classId: _classroom!['id'] as String,
        schoolId: _classroom!['schoolId'] as String,
        teacherId: currentUser.uid,
        date: attendanceDate,
        status: student['status']!,
        term: _term,
      );
    }).toList();

    await _attendanceService.saveAttendance(records);
  }

  // ------------------------------------------------------------
  // CONFIRMATION DIALOG
  // ------------------------------------------------------------

  void _showConfirmationDialog(int present, int absent, int late) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text(
            'Save Attendance?',
            style: TextStyle(
              color: Color(0xFF17212F),
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please confirm the attendance for ${_classroom?['name']}.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF737986)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryItem('Present', present, const Color(0xFF25C98A)),
                  _summaryItem('Absent', absent, const Color(0xFFFF5B65)),
                  _summaryItem('Late', late, const Color(0xFFF2B632)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF737986),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () async {
                      Navigator.pop(dialogContext);

                      setState(() {
                        _isSaving = true;
                      });

                      try {
                        await _persistAttendance();

                        if (!mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context).hideCurrentSnackBar();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Color(0xFF25A875),
                            content: Text('Attendance saved successfully.'),
                          ),
                        );
                        _returnToAttendance(saved: true);
                      } catch (error) {
                        debugPrint('Attendance save error: $error');

                        if (!mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context).hideCurrentSnackBar();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Color(0xFFFF5B65),
                            content: Text(
                              'Could not save attendance. '
                              'Please try again.',
                            ),
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isSaving = false;
                          });
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F67EA),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // SUMMARY ITEM
  // ------------------------------------------------------------

  Widget _summaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF737986)),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // SCREEN
  // ------------------------------------------------------------

  void _selectDate(DateTime date) {
    if (date.isBefore(DateTime(2020))) return;
    setState(() {
      _date = date;
      _term = AttendanceRecord.termForDate(date);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        bottomNavigationBar: AttendanceNavigation(
          teacher: true,
          enabled: !_isSaving,
          teacherLayout: true,
        ),
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: _isSaving
                ? null
                : () {
                    _returnToAttendance();
                  },
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Color(0xFF17212F),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Save attendance',
              onPressed: _isSaving || students.isEmpty ? null : _saveAttendance,
              icon: const Icon(Icons.check_rounded),
            ),
          ],
          title: Text(
            'Marks & Attendance',
            style: const TextStyle(
              color: Color(0xFF17212F),
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text(_error!, textAlign: TextAlign.center))
            : SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Marks',
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFF2563EB),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(6),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Attendance',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Previous day',
                              onPressed: _isSaving || widget.existing.isNotEmpty
                                  ? null
                                  : () => _selectDate(
                                      _date.subtract(const Duration(days: 1)),
                                    ),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Expanded(
                              child: TextButton(
                                onPressed:
                                    _isSaving || widget.existing.isNotEmpty
                                    ? null
                                    : () async {
                                        final date = await showDatePicker(
                                          context: context,
                                          initialDate: _date,
                                          firstDate: DateTime(2020),
                                          lastDate: DateTime.now(),
                                        );
                                        if (date != null && mounted) {
                                          _selectDate(date);
                                        }
                                      },
                                child: Text(
                                  '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    color: Color(0xFF17212F),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Next day',
                              onPressed:
                                  _isSaving ||
                                      widget.existing.isNotEmpty ||
                                      !DateTime(
                                        _date.year,
                                        _date.month,
                                        _date.day,
                                      ).isBefore(
                                        DateTime(
                                          DateTime.now().year,
                                          DateTime.now().month,
                                          DateTime.now().day,
                                        ),
                                      )
                                  ? null
                                  : () => _selectDate(
                                      _date.add(const Duration(days: 1)),
                                    ),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFF2563EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_classroom?['name']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _term,
                                items: [1, 2, 3]
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(
                                          'Term $t',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _isSaving
                                    ? null
                                    : (t) => setState(() => _term = t!),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: students.isEmpty
                          ? const Center(
                              child: Text(
                                'No students enrolled in this class.',
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: students.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 9),
                              itemBuilder: (context, index) {
                                return _buildStudentCard(index);
                              },
                            ),
                    ),

                    // ----------------------------------------------------
                    // SAVE BUTTON
                    // ----------------------------------------------------
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Color(0xFFE9EBEF)),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving || students.isEmpty
                              ? null
                              : _saveAttendance,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F67EA),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.3,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Attendance',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // ------------------------------------------------------------
  // STUDENT CARD
  // ------------------------------------------------------------

  Widget _buildStudentCard(int index) {
    final student = students[index];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFDCEBFF),
            child: Text(
              student['initials']!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF2F67EA),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF17212F),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${student['id']}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          _buildStatusButton(index, 'P'),
          const SizedBox(width: 6),
          _buildStatusButton(index, 'A'),
          const SizedBox(width: 6),
          _buildStatusButton(index, 'L'),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // P / A / L BUTTON
  // ------------------------------------------------------------

  Widget _buildStatusButton(int index, String status) {
    final bool selected = students[index]['status'] == status;

    Color color;

    if (status == 'P') {
      color = const Color(0xFF25C98A);
    } else if (status == 'A') {
      color = const Color(0xFFFF5B65);
    } else {
      color = const Color(0xFFF2B632);
    }

    return Tooltip(
      message: status == 'P'
          ? 'Present'
          : status == 'A'
          ? 'Absent'
          : 'Late',
      child: InkWell(
        onTap: _isSaving
            ? null
            : () {
                setState(() {
                  students[index]['status'] = status;
                });
              },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : const Color(0xFFF1F2F4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: selected ? color : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
