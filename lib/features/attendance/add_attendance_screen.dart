import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/attendance_record.dart';
import 'services/attendance_service.dart';
import '../user_communication/teacher_chat_fab.dart';

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

  final List<Map<String, String>> students = [];
  Map<String, dynamic>? _classroom;
  bool _loading = true;
  String? _error;
  DateTime _date = DateTime.now();
  int _term = 1;

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Save Attendance?',
            style: TextStyle(
              color: Color(0xFF151B2B),
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
                        Navigator.pop(context, true);
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
            borderRadius: BorderRadius.circular(10),
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6F8),
        // Lifted so it sits above the fixed Save Attendance bar.
        floatingActionButton: const TeacherChatFab(bottomOffset: 70),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: _isSaving
                ? null
                : () {
                    Navigator.pop(context);
                  },
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Color(0xFF151B2B),
            ),
          ),
          title: Text(
            widget.existing.isEmpty ? 'Add Attendance' : 'Update Attendance',
            style: const TextStyle(
              color: Color(0xFF151B2B),
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
                    // ----------------------------------------------------
                    // CLASS INFORMATION
                    // ----------------------------------------------------

                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_classroom?['name']}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF151B2B),
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Select attendance for each student',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9297A1),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // TODAY LABEL
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF1FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 15,
                                  color: Color(0xFF2F67EA),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '${_date.day}/${_date.month}/${_date.year}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2F67EA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ----------------------------------------------------
                    // STUDENT LIST
                    // ----------------------------------------------------
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              '${_date.year}-${_date.month}-${_date.day}',
                            ),
                            onPressed: _isSaving || widget.existing.isNotEmpty
                                ? null
                                : () async {
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate: _date,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                    );
                                    if (date != null && mounted) {
                                      setState(() => _date = date);
                                    }
                                  },
                          ),
                          const Spacer(),
                          DropdownButton<int>(
                            value: _term,
                            items: [1, 2, 3]
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text('Term $t'),
                                  ),
                                )
                                .toList(),
                            onChanged: _isSaving
                                ? null
                                : (t) => setState(() => _term = t!),
                          ),
                        ],
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
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                kTeacherFabClearance,
                              ),
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
                              borderRadius: BorderRadius.circular(11),
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
        borderRadius: BorderRadius.circular(12),
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
                    color: Color(0xFF151B2B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${student['id']}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9297A1),
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

    return InkWell(
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
        width: 27,
        height: 27,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : const Color(0xFFF1F2F4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? color : const Color(0xFF8B909A),
          ),
        ),
      ),
    );
  }
}
