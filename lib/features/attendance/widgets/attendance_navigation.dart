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
        ? BottomNavigationBar(
            currentIndex: 1,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 0,
            selectedItemColor: const Color(0xFF2563EB),
            unselectedItemColor: const Color(0xFF6B7280),
            selectedFontSize: 10,
            unselectedFontSize: 10,
            onTap: !enabled
                ? null
                : (index) {
                    if (index == 1) {
                      _navigate(context, 1);
                      return;
                    }
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => TeacherDashboard(initialIndex: index),
                      ),
                      (_) => false,
                    );
                  },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                label: 'Classes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                label: 'Tasks',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Profile',
              ),
            ],
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
