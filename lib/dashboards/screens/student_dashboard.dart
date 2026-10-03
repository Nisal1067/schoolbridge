import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/dashboard_item.dart';
import '../../core/widgets/placeholder.dart';
import '../../features/attendance/parent_attendance_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int selectedIndex = 0;

  final pages = const ['Home', 'Homework', 'Results', 'Attendance', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SchoolBridge'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),

      body: selectedIndex == 0
          ? _StudentHome(
              onNavigate: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
            )
          : PlaceholderPage(title: pages[selectedIndex]),

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: 'Homework',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Results',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
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
}

class _StudentHome extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const _StudentHome({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good Morning!', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 6),
              Text(
                'Welcome back, Student',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Quick Access',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        DashboardItem(
          icon: Icons.assignment,
          title: 'Homework',
          subtitle: 'View assigned homework',
          onTap: () => onNavigate(1),
        ),

        DashboardItem(
          icon: Icons.bar_chart,
          title: 'Results',
          subtitle: 'View academic results',
          onTap: () => onNavigate(2),
        ),

        DashboardItem(
          icon: Icons.fact_check,
          title: 'Attendance',
          subtitle: 'View attendance status',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ParentAttendanceScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}
