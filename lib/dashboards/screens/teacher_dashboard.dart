import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'dart:async';

import '../../auth/widgets/logout_button.dart';

import '../../features/attendance/attendance_screen.dart';
import '../../features/profile/teacher_profile_screen.dart';
import '../../auth/services/session_navigation.dart';
import '../../features/homework_announcements/homework_announcements_screen.dart';
import '../../features/marks/marks_screen.dart'; // MARKS: new import
import '../../features/user_communication/teacher_chat_fab.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/notifications/services/notification_service.dart';
import '../../features/notifications/models/in_app_notification.dart';

class TeacherDashboard extends StatefulWidget {
  final int initialIndex;
  const TeacherDashboard({super.key, this.initialIndex = 0});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  late int selectedIndex = widget.initialIndex;

  final List<String> pages = const [
    'Home',
    'Marks',
    'Tasks',
    'Attendance',
    'Profile',
  ];

  StreamSubscription? _notifSub;
  int _lastNotifCount = 0;

  @override
  void initState() {
    super.initState();
    _notifSub = NotificationService().myNotifications.listen((notifications) {
      if (!mounted) return;
      final unreadCount = notifications.where((n) => !n.isRead).length;
      if (unreadCount > _lastNotifCount &&
          notifications.isNotEmpty &&
          !notifications.first.isRead) {
        if (_lastNotifCount != 0) {
          final newNotif = notifications.first;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${newNotif.title}\n${newNotif.body}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF1E40AF),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'View',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
            ),
          );
        }
        _lastNotifCount = unreadCount;
      } else if (unreadCount < _lastNotifCount) {
        _lastNotifCount = unreadCount;
      }
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Icon(Icons.school_rounded, color: Color(0xFF1E40AF), size: 28),
            SizedBox(width: 8),
            Text(
              'SchoolBridge',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<List<InAppNotification>>(
            stream: NotificationService().myNotifications,
            builder: (context, snapshot) {
              final unreadCount =
                  snapshot.data?.where((n) => !n.isRead).length ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      size: 26,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const LogoutButton(),
        ],
      ),

      body: SafeArea(
        child: selectedIndex == 0
            ? _TeacherHome(
                onNavigate: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
              )
            : selectedIndex == 4
            ? const TeacherProfileScreen(isTab: true)
            : selectedIndex == 1
            ? const MarksScreen() // MARKS: Marks tab
            : selectedIndex == 2
            ? const HomeworkAnnouncementsScreen()
            : selectedIndex == 3
            ? const AttendanceScreen(showBackButton: false)
            : _PlaceholderPage(title: pages[selectedIndex]),
      ),

      floatingActionButton: const TeacherChatFab(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Theme(
      data: Theme.of(context).copyWith(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: NavigationBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 15,
        indicatorColor: const Color(0xFFDBEAFE),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          SessionNavigation.remember('teacher', {'index': index});
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
            icon: Icon(Icons.grading_outlined),
            selectedIcon: Icon(Icons.grading),
            label: 'Marks',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: 'Tasks',
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
    );
  }
}

class _TeacherHome extends StatefulWidget {
  final ValueChanged<int> onNavigate;

  const _TeacherHome({required this.onNavigate});

  @override
  State<_TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<_TeacherHome> {
  void _showAllSchedule() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.72,
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .snapshots(),
            builder: (context, snapshot) {
              final rawSchedule = snapshot.data?.data()?['schedule'];
              final schedule = rawSchedule is List
                  ? rawSchedule.whereType<Map>().toList()
                  : <Map>[];
              final days = [
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
                'Saturday',
                'Sunday',
              ];
              schedule.sort((a, b) {
                final dayCompare = days
                    .indexOf(a['day']?.toString() ?? '')
                    .compareTo(days.indexOf(b['day']?.toString() ?? ''));
                return dayCompare != 0
                    ? dayCompare
                    : (a['time']?.toString() ?? '').compareTo(
                        b['time']?.toString() ?? '',
                      );
              });

              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All Schedules',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: snapshot.connectionState == ConnectionState.waiting
                          ? const Center(child: CircularProgressIndicator())
                          : schedule.isEmpty
                          ? const Center(
                              child: Text('No schedules have been added yet.'),
                            )
                          : ListView.separated(
                              itemCount: schedule.length,
                              separatorBuilder: (_, index) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = schedule[index];
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: const BorderSide(
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFFEEF2FF),
                                    child: Icon(
                                      Icons.calendar_month_outlined,
                                      color: Color(0xFF4F46E5),
                                    ),
                                  ),
                                  title: Text(
                                    '${item['subject'] ?? 'Subject'} - ${item['className'] ?? 'Class'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${item['day'] ?? ''} - ${item['time'] ?? ''}${(item['room'] ?? '').toString().isEmpty ? '' : ' - ${item['room']}'}',
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

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
                  colors: [
                    Color(0xFF1E40AF),
                    Color(0xFF3B82F6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E40AF).withValues(alpha: 0.28),
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
                      : 'Teacher';
                  String fallbackName = user?.displayName ?? defaultEmailName;
                  if (fallbackName.isNotEmpty && !fallbackName.contains(' ')) {
                    fallbackName =
                        fallbackName[0].toUpperCase() +
                        fallbackName.substring(1);
                  }

                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      String teacherName = fallbackName;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data();
                        if (data != null &&
                            data['name'] != null &&
                            data['name'].toString().trim().isNotEmpty) {
                          teacherName = data['name'].toString().trim();
                        }
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome,\n$teacherName!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Have a productive teaching day!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.grading_rounded,
                          iconColor: const Color(0xFF1E40AF),
                          iconBg: const Color(0xFFDBEAFE),
                          title: 'Marks',
                          subtitle: 'Scores & Results',
                          onTap: () => widget.onNavigate(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.assignment_rounded,
                          iconColor: const Color(0xFFD97706),
                          iconBg: const Color(0xFFFEF3C7),
                          title: 'Homeworks',
                          subtitle: 'Assignments',
                          onTap: () => widget.onNavigate(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.calendar_today_rounded,
                          iconColor: const Color(0xFF059669),
                          iconBg: const Color(0xFFD1FAE5),
                          title: 'Attendance',
                          subtitle: 'Daily Tracking',
                          onTap: () => widget.onNavigate(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.chat_bubble_rounded,
                          iconColor: const Color(0xFFDB2777),
                          iconBg: const Color(0xFFFCE7F3),
                          title: 'Messages',
                          subtitle: 'Chats',
                          onTap: () => openTeacherChat(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Schedule",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0,
                        ),
                      ),
                      TextButton(
                        onPressed: _showAllSchedule,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1E40AF),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final data = snapshot.hasData
                          ? snapshot.data!.data() ?? {}
                          : {};
                      final allSchedule = data['schedule'] is List
                          ? data['schedule'] as List
                          : <dynamic>[];
                      final today = <String>[
                        'Monday',
                        'Tuesday',
                        'Wednesday',
                        'Thursday',
                        'Friday',
                        'Saturday',
                        'Sunday',
                      ][DateTime.now().weekday - 1];
                      final schedule = allSchedule
                          .where(
                            (item) =>
                                item is Map && item['day']?.toString() == today,
                          )
                          .toList();

                      if (schedule.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_available_rounded,
                                size: 40,
                                color: Color(0xFFCBD5E1),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No classes scheduled for today',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: schedule.map((item) {
                          if (item is! Map) return const SizedBox.shrink();
                          final time = item['time']?.toString() ?? 'N/A';
                          final grade =
                              item['className']?.toString() ?? 'Unknown Class';
                          final subject =
                              item['subject']?.toString() ?? 'General';
                          // Give some variety in color based on index or subject
                          final isMath = subject.toLowerCase().contains('math');
                          final isSci = subject.toLowerCase().contains('sci');
                          final color = isMath
                              ? const Color(0xFF1E40AF)
                              : (isSci
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF059669));

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ScheduleCard(
                              time: time,
                              grade: grade,
                              subject: subject,
                              color: color,
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Color(0xFF0F172A),
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final String time;
  final String grade;
  final String subject;
  final Color color;

  const _ScheduleCard({
    required this.time,
    required this.grade,
    required this.subject,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.schedule_rounded, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subject,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              time,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;

  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      ),
    );
  }
}
