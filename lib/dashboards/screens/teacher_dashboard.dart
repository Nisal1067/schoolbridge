import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/dashboard_item.dart';
import '../../core/widgets/placeholder.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int selectedIndex = 0;

  final pages = const ['Home', 'Classes', 'Tasks', 'Chat', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),

      body: selectedIndex == 0
          ? _TeacherHome(
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
            icon: Icon(Icons.class_outlined),
            label: 'Classes',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
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

class _TeacherHome extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const _TeacherHome({required this.onNavigate});

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
              Text(
                'Teacher Dashboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Manage your classes and students',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        DashboardItem(
          icon: Icons.class_,
          title: 'My Classes',
          subtitle: 'View and manage classes',
          onTap: () => onNavigate(1),
        ),

        DashboardItem(
          icon: Icons.bar_chart,
          title: 'Marks & Attendance',
          subtitle: 'Manage student marks and attendance',
          onTap: () {},
        ),

        DashboardItem(
          icon: Icons.assignment,
          title: 'Homework & Tasks',
          subtitle: 'Manage homework and assignments',
          onTap: () => onNavigate(2),
        ),

        DashboardItem(
          icon: Icons.chat,
          title: 'Messages',
          subtitle: 'Communicate with parents',
          onTap: () => onNavigate(3),
        ),
      ],
    );
  }
}
