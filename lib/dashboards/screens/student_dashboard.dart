import 'package:flutter/material.dart';

import '../../auth/widgets/logout_button.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/placeholder.dart';
import '../../features/attendance/parent_attendance_screen.dart';
import '../../features/homework_announcements/student/student_homework_screen.dart';
import '../../features/attendance/services/attendance_service.dart';
import '../../features/profile/student_profile_screen.dart';

// MARKS - Import Student Results Screen
import '../../features/marks/student/student_results_screen.dart';

class StudentDashboard extends StatefulWidget {
  final int initialIndex;
  const StudentDashboard({super.key, this.initialIndex = 0});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  late int selectedIndex = widget.initialIndex;
  late Future<Map<String, dynamic>> _studentProfile;

  final pages = const ['Home', 'Homework', 'Results', 'Attendance', 'Profile'];

  @override
  void initState() {
    super.initState();
    _studentProfile = AttendanceService().profile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: selectedIndex == 1
          ? null
          : AppBar(
              backgroundColor: const Color(0xFFF8FAFC),
              elevation: 0,
              title: const Row(
                children: [
                  Icon(
                    Icons.school_rounded,
                    color: Color(0xFF4F46E5),
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'SchoolBridge',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              surfaceTintColor: Colors.transparent,
              actions: [
                const LogoutButton(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none),
                ),
              ],
            ),

      body: selectedIndex == 0
          ? FutureBuilder<Map<String, dynamic>>(
              future: _studentProfile,
              builder: (context, snapshot) {
                final name = (snapshot.data?['name'] ?? 'Student').toString();
                return _StudentHome(
                  studentName: name,
                  onNavigate: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                );
              },
            )
          : selectedIndex == 1
          ? const SafeArea(child: StudentHomeworkScreen())
          // MARKS - Open Student Results Screen when Results tab is selected
          : selectedIndex == 2
          ? const StudentResultsScreen()
          : selectedIndex == 4
          ? const StudentProfileScreen(isTab: true)
          : PlaceholderPage(title: pages[selectedIndex]),

      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 15,
          indicatorColor: const Color(0xFFE0E7FF),
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const ParentAttendanceScreen(studentLayout: true),
                ),
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
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'Homework',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Results',
            ),
            NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check),
              label: 'Attendance',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentHome extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  final String studentName;

  const _StudentHome({required this.onNavigate, required this.studentName});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.28),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Good Morning!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome back,\n$studentName!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ready for a productive day?',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _StudentQuickActionCard(
                  icon: Icons.assignment_rounded,
                  iconColor: const Color(0xFF4F46E5),
                  iconBackground: const Color(0xFFEEF2FF),
                  title: 'Homework',
                  subtitle: 'View assignments',
                  onTap: () => onNavigate(1),
                ),
                _StudentQuickActionCard(
                  icon: Icons.bar_chart_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBackground: const Color(0xFFDBEAFE),
                  title: 'Results',
                  subtitle: 'Scores & progress',
                  onTap: () => onNavigate(2),
                ),
                _StudentQuickActionCard(
                  icon: Icons.fact_check_rounded,
                  iconColor: const Color(0xFF059669),
                  iconBackground: const Color(0xFFD1FAE5),
                  title: 'Attendance',
                  subtitle: 'View daily tracking',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ParentAttendanceScreen(studentLayout: true),
                      ),
                    );
                  },
                ),
                _StudentQuickActionCard(
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xFFDB2777),
                  iconBackground: const Color(0xFFFCE7F3),
                  title: 'Profile',
                  subtitle: 'View your details',
                  onTap: () => onNavigate(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentQuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _StudentQuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
