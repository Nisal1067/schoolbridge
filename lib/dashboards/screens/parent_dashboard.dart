import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../auth/widgets/logout_button.dart';

import '../../core/widgets/placeholder.dart';
import '../../features/attendance/parent_attendance_screen.dart';
import '../../features/user_communication/communication_screen.dart';
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
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Parent Dashboard',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
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
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
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
                            'Welcome, $parentName!',
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
                  subtitle: 'View marks and results',
                  icon: Icons.bar_chart_rounded,
                  gradient: const [Color(0xFFF59E0B), Color(0xFFF97316)],
                  onTap: () => onNavigate(1),
                ),
                _buildPremiumCard(
                  title: 'Attendance',
                  subtitle: 'View student attendance records',
                  icon: Icons.fact_check_rounded,
                  gradient: const [Color(0xFF10B981), Color(0xFF059669)],
                  onTap: () => onNavigate(2),
                ),
                _buildPremiumCard(
                  title: 'Homework',
                  subtitle: 'Class announcements and tasks',
                  icon: Icons.assignment_outlined,
                  gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
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
                  title: 'Chat',
                  subtitle: 'Message teachers directly',
                  icon: Icons.chat_bubble_outline_rounded,
                  gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  onTap: () => onNavigate(3),
                ),
              ],
            ),
          ),

          // Profile card full width
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => onNavigate(4),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF475569), Color(0xFF334155)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(color: Color(0x4D334155), blurRadius: 8, offset: Offset(0, 4)),
                              ],
                            ),
                            child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profile',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'View your details & linked students',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: gradient[1].withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
