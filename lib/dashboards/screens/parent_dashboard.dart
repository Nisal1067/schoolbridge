import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../auth/widgets/logout_button.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/dashboard_item.dart';
import '../../core/widgets/placeholder.dart';
import '../../features/attendance/parent_attendance_screen.dart';
import '../../features/user_communication/communication_screen.dart';
import '../../features/homework_announcements/parent/parent_homework_announcements_screen.dart';
import '../../features/profile/parent_profile_screen.dart';

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
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(Icons.school_rounded, color: Color(0xFF4F46E5), size: 28),
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
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B)),
          ),
          const LogoutButton(),
          const SizedBox(width: 8),
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
          : selectedIndex == 2
          ? const ParentAttendanceScreen(isTab: true)
          : selectedIndex == 3
          ? const CommunicationScreen()
          : selectedIndex == 4
          ? const ParentProfileScreen(isTab: true)
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
      ),
    );
  }
}

class _ParentHome extends StatelessWidget {
  final ValueChanged<int> onNavigate;

  const _ParentHome({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: CustomScrollView(
        slivers: [
          // Elegant Welcome Header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7DD3FC).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
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
                    fallbackName = fallbackName[0].toUpperCase() + fallbackName.substring(1);
                  }

                  if (user == null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, $fallbackName!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Track your child\'s school progress',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    );
                  }

                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                    builder: (context, snapshot) {
                      String parentName = fallbackName;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data();
                        if (data != null && data['name'] != null && data['name'].toString().trim().isNotEmpty) {
                          parentName = data['name'].toString().trim();
                        }
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome,\n$parentName!',
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Here is your child\'s update\nfor today.',
                            style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 16),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => onNavigate(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Color(0xFF3B82F6),
                                      child: Icon(Icons.person, size: 16, color: Colors.white),
                                    ),
                                    const SizedBox(width: 8),
                                    const Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Student Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                                        Text('View Details >', style: TextStyle(fontSize: 10, color: Color(0xFF475569))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),
          
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.95,
              children: [
                _buildPremiumCard(
                  title: 'Academic Progress',
                  value: '78%',
                  icon: Icons.bar_chart_rounded,
                  primaryColor: const Color(0xFF2563EB),
                  backgroundColor: const Color(0xFFDBEAFE),
                  onTap: () => onNavigate(1),
                ),
                _buildPremiumCard(
                  title: 'Attendance',
                  value: '92%',
                  icon: Icons.calendar_month_rounded,
                  primaryColor: const Color(0xFF059669),
                  backgroundColor: const Color(0xFFD1FAE5),
                  onTap: () => onNavigate(2),
                ),
                _buildPremiumCard(
                  title: 'Homework',
                  value: '2 pending',
                  icon: Icons.edit_document,
                  primaryColor: const Color(0xFFD97706),
                  backgroundColor: const Color(0xFFFEF3C7),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ParentHomeworkAnnouncementsScreen(),
                      ),
                    );
                  },
                ),
                _buildPremiumCard(
                  title: 'Messages',
                  value: '1 new',
                  icon: Icons.chat_bubble_rounded,
                  primaryColor: const Color(0xFFDC2626),
                  backgroundColor: const Color(0xFFFEE2E2),
                  onTap: () => onNavigate(3),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Announcements',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ParentHomeworkAnnouncementsScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'View All >',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Build dummy announcement list items mirroring the mockup
          SliverList(
            delegate: SliverChildListDelegate([
              _buildAnnouncementCard('Term Test Timetable Released', 'The timetable for the upcoming term test is now available.', 'Oct 06, 2026', Icons.campaign_rounded, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
              _buildAnnouncementCard('Parent-Teacher Meeting', 'Schedule for the parent-teacher meeting has been published.', 'Oct 04, 2026', Icons.groups_rounded, const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
              _buildAnnouncementCard('Science Project Deadline', 'Final submission date for the science project.', 'Oct 03, 2026', Icons.science_rounded, const Color(0xFF059669), const Color(0xFFECFDF5)),
              _buildAnnouncementCard('School Holiday Notice', 'School will be closed on October 14 for the special holiday.', 'Oct 01, 2026', Icons.edit_calendar_rounded, const Color(0xFFD97706), const Color(0xFFFFFBEB)),
              const SizedBox(height: 20),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard({
    required String title,
    required String value,
    required IconData icon,
    required Color primaryColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: primaryColor.withAlpha(200)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            value,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.chevron_right_rounded, size: 16, color: primaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(String title, String subtitle, String date, IconData icon, Color primaryColor, Color backgroundColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryColor, size: 22),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              date,
              style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
      ),
    );
  }
}
