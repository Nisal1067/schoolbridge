import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/dashboard_item.dart';
import '../../core/widgets/placeholder.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;

  final pages = const ['Home', 'Users', 'Reports', 'Announcements', 'Settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),

      body: selectedIndex == 0
          ? _AdminHome(
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
            icon: Icon(Icons.group_outlined),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _AdminHome extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const _AdminHome({required this.onNavigate});

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
                'Welcome, Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Manage SchoolBridge',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        DashboardItem(
          icon: Icons.manage_accounts,
          title: 'User Management',
          subtitle: 'Manage school users',
          onTap: () => onNavigate(1),
        ),

        DashboardItem(
          icon: Icons.bar_chart_outlined,
          title: 'Reports',
          subtitle: 'View school reports',
          onTap: () => onNavigate(2),
        ),

        DashboardItem(
          icon: Icons.campaign_outlined,
          title: 'Announcements',
          subtitle: 'Manage announcements',
          onTap: () => onNavigate(3),
        ),

        DashboardItem(
          icon: Icons.settings_outlined,
          title: 'Settings',
          subtitle: 'System settings',
          onTap: () => onNavigate(4),
        ),
      ],
    );
  }
}
