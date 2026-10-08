import 'package:flutter/material.dart';

import 'widgets/attendance_navigation.dart';

import 'models/attendance_record.dart';
import 'widgets/student_attendance_view.dart';

import 'parent_attendance_report_screen.dart';

class ParentAttendanceScreen extends StatefulWidget {
  final bool isTab;
  const ParentAttendanceScreen({super.key, this.isTab = false});

  @override
  State<ParentAttendanceScreen> createState() => _ParentAttendanceScreenState();
}

class _ParentAttendanceScreenState extends State<ParentAttendanceScreen> {
  int selectedView = 0; // 0: This Month, 1: Term 1, 2: Term 2, 3: Term 3

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      bottomNavigationBar: widget.isTab ? null : AttendanceNavigation(),

      appBar: widget.isTab ? null : AppBar(
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
            onPressed: () {},
            icon: const Icon(
              Icons.file_download_outlined,
              color: Color(0xFF2F67EA),
            ),
          ),
        ],
      ),

      body: StudentAttendanceView(
        builder: (student, records) {
          final filtered = records.where((r) {
            if (selectedView == 0) {
              final now = DateTime.now();
              return r.date.year == now.year && r.date.month == now.month;
            }
            return r.term == selectedView;
          }).toList();
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
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(selectedView == 0 ? 'No attendance recorded for this month.' : 'No attendance recorded for this term.'),
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
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _termButton('This Month', 0),
          _termButton('Term 1', 1),
          _termButton('Term 2', 2),
          _termButton('Term 3', 3),
        ],
      ),
    );
  }

  Widget _termButton(String title, int index) {
    final bool selected = selectedView == index;

    return InkWell(
      onTap: () {
        setState(() {
          selectedView = index;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)])
              : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF64748B),
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
      child: Column(
        children: [
          const Text(
            'Overall Attendance',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
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
      constraints: const BoxConstraints(minHeight: 135),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
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
    return Container(
      width: double.infinity,
      height: 60,
      margin: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ParentAttendanceReportScreen(
                initialView: selectedView,
                initialStudentId: studentId,
              ),
            ),
          );
        },
        icon: const Icon(Icons.analytics_outlined, size: 22),
        label: const Text(
          'View Detailed Report',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2563EB),
          elevation: 4,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }
}
