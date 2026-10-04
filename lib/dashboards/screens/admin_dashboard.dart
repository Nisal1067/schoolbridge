import 'package:flutter/material.dart';
import '../../auth/widgets/logout_button.dart';
import '../../core/widgets/placeholder.dart';
import '../../features/announcements/screens/announcements_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/user_management/screens/users_list_screen.dart';
import '../../features/user_management/widgets/admin_bottom_nav_bar.dart';
import '../../features/user_management/widgets/custom_app_bar.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;

  Widget _buildBody() {
    switch (selectedIndex) {
      case 0:
        return _AdminHome(
          onNavigate: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
        );
      case 1:
        return const UsersListScreen();
      case 2:
        return const ReportsScreen();
      case 3:
        return const AnnouncementsScreen();
      case 4:
        return const SettingsScreen(showBackButton: false);
      default:
        return const PlaceholderPage(title: 'SchoolBridge');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: const Color(0xFF2563EB),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.admin_panel_settings, size: 36, color: Colors.white),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'SchoolBridge Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'admin@schoolbridge.lk',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => selectedIndex = 0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('User Management'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => selectedIndex = 1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart_outlined),
                title: const Text('Reports'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => selectedIndex = 2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_none_outlined),
                title: const Text('Announcements & Alerts'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => selectedIndex = 3);
                },
              ),
              const Spacer(),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text('Session', style: TextStyle(color: Colors.grey)),
                    Spacer(),
                    LogoutButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: AdminBottomNavBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
    );
  }
}

class _AdminHome extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const _AdminHome({required this.onNavigate});

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFDCEBFE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2563EB),
              size: 22,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String time,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEBFE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: const Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: const SchoolBridgeAppBar(title: 'SchoolBridge'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            // Welcome Header
            const Text(
              'Welcome, Admin',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'School overview and monitoring',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),

            const SizedBox(height: 18),

            // 2x2 Stat Cards Grid
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onNavigate(1),
                    child: _buildStatCard(
                      icon: Icons.person_outline_rounded,
                      value: '320',
                      label: 'Students',
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onNavigate(1),
                    child: _buildStatCard(
                      icon: Icons.school_outlined,
                      value: '25',
                      label: 'Teachers',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onNavigate(2),
                    child: _buildStatCard(
                      icon: Icons.menu_book_outlined,
                      value: '12',
                      label: 'Classes',
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onNavigate(2),
                    child: _buildStatCard(
                      icon: Icons.trending_up_rounded,
                      value: '94%',
                      label: 'Attendance',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Activity Section
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            _buildActivityItem(
              icon: Icons.person_add_alt_1_outlined,
              title: 'New student registered',
              time: '2 minutes ago',
              onTap: () => onNavigate(1),
            ),
            _buildActivityItem(
              icon: Icons.upload_file_outlined,
              title: 'Results uploaded',
              time: '1 hour ago',
              onTap: () => onNavigate(2),
            ),

            const SizedBox(height: 20),

            // Quick Actions Section
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Announcements Action Card
                Expanded(
                  child: GestureDetector(
                    onTap: () => onNavigate(3),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0EDFD),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Announcements',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Post school update',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Emergency Alert Action Card
                Expanded(
                  child: GestureDetector(
                    onTap: () => onNavigate(3),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE8EC),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency Alert',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Send urgent notice',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
