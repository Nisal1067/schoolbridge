import 'package:flutter/material.dart';

import 'add_attendance_screen.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

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

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CLASS INFORMATION
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
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
                            'Grade 10A',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF151B2B),
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            '32 Students',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9297A1),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddAttendanceScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Add Attendance',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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

              _attendanceRecord(
                context,
                date: '18 May 2026',
                present: 28,
                absent: 3,
                late: 1,
              ),

              const SizedBox(height: 10),

              _attendanceRecord(
                context,
                date: '17 May 2026',
                present: 30,
                absent: 2,
                late: 0,
              ),

              const SizedBox(height: 10),

              _attendanceRecord(
                context,
                date: '16 May 2026',
                present: 29,
                absent: 2,
                late: 1,
              ),
            ],
          ),
        ),
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
