import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../auth/widgets/logout_button.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/dashboard_item.dart';
import '../../core/widgets/placeholder.dart';
import '../../features/attendance/parent_attendance_screen.dart';
import '../../features/homework_announcements/parent/parent_homework_announcements_screen.dart';

class ParentDashboard extends StatefulWidget {
  final int initialIndex;
  const ParentDashboard({super.key, this.initialIndex = 0});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  late int selectedIndex = widget.initialIndex;

  final pages = const [
    'Home',
    'Academic Progress',
    'Attendance',
    'Chat',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent'),
        actions: [
          const LogoutButton(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),

      body: selectedIndex == 0
          ? _ParentHome(
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
          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ParentAttendanceScreen()),
            );
            return;
          }
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
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            label: 'Attendance',
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

class _ParentHome extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const _ParentHome({required this.onNavigate});

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
          child: Builder(
            builder: (context) {
              final user = FirebaseAuth.instance.currentUser;
              final defaultEmailName =
                  user?.email != null && user!.email!.contains('@')
                  ? user.email!.split('@').first
                  : 'Parent';
              String fallbackName = user?.displayName ?? defaultEmailName;
              if (fallbackName.isNotEmpty && !fallbackName.contains(' ')) {
                fallbackName =
                    fallbackName[0].toUpperCase() + fallbackName.substring(1);
              }

              if (user == null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $fallbackName!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Track your child\'s school progress',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                );
              }

              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  String parentName = fallbackName;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data();
                    if (data != null &&
                        data['name'] != null &&
                        data['name'].toString().trim().isNotEmpty) {
                      parentName = data['name'].toString().trim();
                    }
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $parentName!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Track your child\'s school progress',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        DashboardItem(
          icon: Icons.bar_chart,
          title: 'Academic Progress',
          subtitle: 'View marks and results',
          onTap: () => onNavigate(1),
        ),

        DashboardItem(
          icon: Icons.fact_check,
          title: 'Attendance',
          subtitle: 'View attendance records',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ParentAttendanceScreen(),
              ),
            );
          },
        ),

        DashboardItem(
          icon: Icons.assignment_outlined,
          title: 'Homework & Announcements',
          subtitle: "Homework, school and class updates",
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ParentHomeworkAnnouncementsScreen(),
              ),
            );
          },
        ),

        DashboardItem(
          icon: Icons.chat_outlined,
          title: 'Teacher Communication',
          subtitle: 'Message teachers',
          onTap: () => onNavigate(3),
        ),

        DashboardItem(
          icon: Icons.person_outline,
          title: 'Profile',
          subtitle: 'Student information',
          onTap: () => onNavigate(4),
        ),
      ],
    );
  }
}
