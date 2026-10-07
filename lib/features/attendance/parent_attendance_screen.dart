import 'package:flutter/material.dart';

import 'widgets/attendance_navigation.dart';

import 'models/attendance_record.dart';
import 'widgets/student_attendance_view.dart';

import 'parent_attendance_report_screen.dart';

class ParentAttendanceScreen extends StatefulWidget {
  const ParentAttendanceScreen({super.key});

  @override
  State<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends State<ParentAttendanceScreen> {
  int selectedTerm = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      bottomNavigationBar: AttendanceNavigation(),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 19,
            color: Color(0xFF2F67EA),
          ),
        ),

        title: const Text(
          'Attendance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF17212F),
          ),
        ),

        actions: [
          IconButton(
            onPressed: () {
              // Download report functionality later
            },
            icon: const Icon(
              Icons.file_download_outlined,
              color: Color(0xFF2F67EA),
            ),
          ),
        ],
      ),

      body: StudentAttendanceView(
        builder: (student, records) {
          final filtered = records.where((r) => r.term == selectedTerm + 1);
          final data = AttendanceRecord.summary(filtered);
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ------------------------------------------------
                  // TERM SELECTOR
                  // ------------------------------------------------

                  _buildTermSelector(),

                  const SizedBox(height: 20),

                  // ------------------------------------------------
                  // OVERALL ATTENDANCE
                  // ------------------------------------------------
                  _buildOverallAttendance(data['attendance'] as int),

                  const SizedBox(height: 14),

                  // ------------------------------------------------
                  // STATISTICS
                  // ------------------------------------------------
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatisticCard(
                          icon: Icons.person_outline,
                          title: 'Present',
                          value: '${data['present']}',
                          color: const Color(0xFF25C98A),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _buildStatisticCard(
                          icon: Icons.cancel_outlined,
                          title: 'Absent',
                          value: '${data['absent']}',
                          color: const Color(0xFFFF5B65),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildStatisticCard(
                          icon: Icons.access_time,
                          title: 'Late',
                          value: '${data['late']}',
                          color: const Color(0xFFF2B632),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: _buildStatisticCard(
                          icon: Icons.calendar_month_outlined,
                          title: 'Total Days',
                          value: '${data['totalDays']}',
                          color: const Color(0xFF2F67EA),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ------------------------------------------------
                  // VIEW ATTENDANCE REPORT
                  // ------------------------------------------------
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No attendance recorded for this term.'),
                    ),
                  _buildReportButton(context, student['id'] as String),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // TERM SELECTOR
  // ============================================================

  Widget _buildTermSelector() {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _termButton('Term 1', 0),
          _termButton('Term 2', 1),
          _termButton('Term 3', 2),
        ],
      ),
    );
  }

  Widget _termButton(String title, int index) {
    final bool selected = selectedTerm == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedTerm = index;
          });
        },
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2F67EA) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OVERALL ATTENDANCE
  // ============================================================

  Widget _buildOverallAttendance(int percentage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Overall Attendance',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 4),

          Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1473E6),
            ),
          ),

          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 7,
              backgroundColor: const Color(0xFFE8EEF8),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF2F67EA),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATISTIC CARD
  // ============================================================

  Widget _buildStatisticCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      height: 125,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: color),
          ),

          const SizedBox(height: 8),

          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17212F),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REPORT BUTTON
  // ============================================================

  Widget _buildReportButton(BuildContext context, String studentId) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ParentAttendanceReportScreen(
                initialTerm: selectedTerm,
                initialStudentId: studentId,
              ),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 19,
                  color: Color(0xFF2F67EA),
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: Text(
                  'View Attendance Report',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF17212F),
                  ),
                ),
              ),

              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
