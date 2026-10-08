import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../dashboards/screens/teacher_dashboard.dart';
import '../../../dashboards/screens/student_dashboard.dart';
import '../../../dashboards/screens/parent_dashboard.dart';
import '../attendance_screen.dart';
import '../parent_attendance_screen.dart';

class AttendanceNavigation extends StatelessWidget {
  final bool enabled;
  final bool teacher;
  final bool teacherLayout;
  const AttendanceNavigation({
    super.key,
    this.enabled = true,
    this.teacher = false,
    this.teacherLayout = false,
  });

  Future<void> _navigate(BuildContext context, int index) async {
    if (!enabled) return;
    String role = 'teacher';
    if (!teacher) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      try {
        final profile = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        role = profile.data()?['role'] as String? ?? '';
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open navigation. Please retry.'),
            ),
          );
        }
        return;
      }
    }
    if (!context.mounted) return;
    if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => role == 'teacher'
              ? const AttendanceScreen()
              : const ParentAttendanceScreen(),
        ),
      );
      return;
    }
    final tab = index == 2 ? 4 : 0;
    final Widget dashboard = switch (role) {
      'teacher' => TeacherDashboard(initialIndex: tab),
      'student' => StudentDashboard(initialIndex: tab),
      'parent' => ParentDashboard(initialIndex: tab),
      _ => const SizedBox.shrink(),
    };
    if (!['teacher', 'student', 'parent'].contains(role)) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => dashboard),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
    ),
    child: teacherLayout
        ? Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: NavigationBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 15,
              indicatorColor: const Color(0xFFE0E7FF),
              selectedIndex: 3, // Since Attendance is index 3 in TeacherDashboard
              onDestinationSelected: !enabled
                  ? null
                  : (index) {
                      if (index == 3) {
                        _navigate(context, 1); // Internal index 1 for attendance navigation logic
                        return;
                      }
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => TeacherDashboard(initialIndex: index),
                        ),
                        (_) => false,
                      );
                    },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.grading_outlined),
                  selectedIcon: Icon(Icons.grading),
                  label: 'Marks',
                ),
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  label: 'Tasks',
                ),
                NavigationDestination(
                  icon: Icon(Icons.fact_check_outlined),
                  selectedIcon: Icon(Icons.fact_check),
                  label: 'Attendance',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
              ],
            ),
          )
        : NavigationBar(
            height: 68,
            elevation: 0,
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFE0F2FE),
            selectedIndex: 1,
            onDestinationSelected: enabled
                ? (index) => _navigate(context, index)
                : null,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.fact_check_outlined),
                selectedIcon: Icon(Icons.fact_check),
                label: 'Attendance',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
          ),
  );
}
