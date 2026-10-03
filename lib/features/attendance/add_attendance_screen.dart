import 'package:flutter/material.dart';

class AddAttendanceScreen extends StatefulWidget {
  const AddAttendanceScreen({super.key});

  @override
  State<AddAttendanceScreen> createState() => _AddAttendanceScreenState();
}

class _AddAttendanceScreenState extends State<AddAttendanceScreen> {
  final List<Map<String, String>> students = [
    {'initials': 'NS', 'name': 'Nipuni Silva', 'id': '1023', 'status': ''},
    {'initials': 'AP', 'name': 'Arjun Perera', 'id': '1045', 'status': ''},
    {'initials': 'SJ', 'name': 'Sarah Jenkins', 'id': '1089', 'status': ''},
    {'initials': 'MS', 'name': 'Minoli de Silva', 'id': '1102', 'status': ''},
    {'initials': 'RA', 'name': 'Roshan Alwis', 'id': '1154', 'status': ''},
  ];

  // ------------------------------------------------------------
  // SAVE ATTENDANCE
  // ------------------------------------------------------------

  void _saveAttendance() {
    final unmarkedStudents = students
        .where((student) => student['status']!.isEmpty)
        .toList();

    // Validate whether all students are marked
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

    // Calculate attendance summary
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
              const Text(
                'Please confirm the attendance for Grade 10A.',
                style: TextStyle(fontSize: 13, color: Color(0xFF737986)),
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
              onPressed: () {
                Navigator.pop(dialogContext);

                // Database CREATE logic will be added later.

                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Color(0xFF25A875),
                    content: Text('Attendance saved successfully.'),
                  ),
                );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Color(0xFF151B2B),
          ),
        ),

        title: const Text(
          'Add Attendance',
          style: TextStyle(
            color: Color(0xFF151B2B),
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grade 10A',
                          style: TextStyle(
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
                    child: const Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 15,
                          color: Color(0xFF2F67EA),
                        ),

                        SizedBox(width: 6),

                        Text(
                          'Today',
                          style: TextStyle(
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
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: students.length,
                separatorBuilder: (context, index) => const SizedBox(height: 9),
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
                border: Border(top: BorderSide(color: Color(0xFFE9EBEF))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveAttendance,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F67EA),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),

                  child: const Text(
                    'Save Attendance',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
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
          // Student initials
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

          // Student name + ID
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

          // Present
          _buildStatusButton(index, 'P'),

          const SizedBox(width: 6),

          // Absent
          _buildStatusButton(index, 'A'),

          const SizedBox(width: 6),

          // Late
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
      onTap: () {
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
