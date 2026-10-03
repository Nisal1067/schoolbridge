import 'package:flutter/material.dart';

import '../../auth/screens/login_screen.dart';
import '../../models/user_role.dart';

import '../academic/academic_screen.dart';
import '../attendance/attendance_screen.dart';
import '../homework_announcements/homework_announcements_screen.dart';
import '../user_communication/communication_screen.dart';

class DashboardScreen extends StatelessWidget {
  final UserRole role;

  const DashboardScreen({super.key, required this.role});

  void openScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${role.displayName} Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome!',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 6),

                  Text('Logged in as ${role.displayName}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          _ModuleCard(
            title: 'Academic Progress',
            subtitle: 'Marks, results and student progress',
            icon: Icons.bar_chart,
            onTap: () {
              openScreen(context, AcademicScreen(role: role));
            },
          ),

          _ModuleCard(
            title: 'Attendance',
            subtitle: 'Attendance records and reports',
            icon: Icons.fact_check_outlined,
            onTap: () {
              openScreen(context, const AttendanceScreen());
            },
          ),

          _ModuleCard(
            title: 'Homework & Announcements',
            subtitle: 'Homework tasks and school updates',
            icon: Icons.assignment_outlined,
            onTap: () {
              openScreen(context, HomeworkAnnouncementsScreen(role: role));
            },
          ),

          if (role != UserRole.student)
            _ModuleCard(
              title: role == UserRole.admin
                  ? 'User Management'
                  : 'Communication',
              subtitle: role == UserRole.admin
                  ? 'Manage system users'
                  : 'Parent-teacher communication',
              icon: role == UserRole.admin
                  ? Icons.manage_accounts
                  : Icons.chat_bubble_outline,
              onTap: () {
                openScreen(context, UserCommunicationScreen(role: role));
              },
            ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(radius: 26, child: Icon(icon)),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(subtitle),
                  ],
                ),
              ),

              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
