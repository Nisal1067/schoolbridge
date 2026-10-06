import 'package:flutter/material.dart';

import '../../auth/widgets/logout_button.dart';

import '../../features/attendance/attendance_screen.dart';
import '../../features/homework_announcements/homework_announcements_screen.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int selectedIndex = 0;

  final List<String> pages = const [
    'Home',
    'Classes',
    'Tasks',
    'Chat',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),

      body: SafeArea(
        child: selectedIndex == 0
            ? _TeacherHome(
                onNavigate: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
              )
            : selectedIndex == 2
            ? const HomeworkAnnouncementsScreen()
            : _PlaceholderPage(title: pages[selectedIndex]),
      ),

      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8EAF0))),
      ),
      child: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: const Color(0xFF246BFD),
        unselectedItemColor: const Color(0xFF737B8C),
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Classes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
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
    return Column(
      children: [
        _buildHeader(),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(),

                const SizedBox(height: 16),

                _buildQuickActions(context),

                const SizedBox(height: 18),

                _buildScheduleHeader(),

                const SizedBox(height: 10),

                const _ScheduleCard(
                  time: '08:00',
                  grade: 'Grade 10A',
                  subject: 'Mathematics',
                ),

                const SizedBox(height: 9),

                const _ScheduleCard(
                  time: '10:00',
                  grade: 'Grade 9B',
                  subject: 'Mathematics',
                ),

                const SizedBox(height: 9),

                const _ScheduleCard(
                  time: '11:00',
                  grade: 'Grade 8D',
                  subject: 'Homework Review',
                ),

                const SizedBox(height: 9),

                const _ScheduleCard(
                  time: '12:00',
                  grade: 'Grade 11A',
                  subject: 'Homework Review',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8EAF0))),
      ),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () {},
            icon: const Icon(Icons.menu, size: 25, color: Color(0xFF172033)),
          ),

          const SizedBox(width: 4),

          const Expanded(
            child: Text(
              'Teacher Dashboard',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Color(0xFF172033),
              ),
            ),
          ),

          const LogoutButton(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  size: 26,
                  color: Color(0xFF172033),
                ),
              ),
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4057),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFDCEAFF),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Color(0xFF246BFD)),
          ),

          SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, Mrs. Nadeesha!',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF246BFD),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Have a great day of teaching!',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6F7787)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.menu_book_outlined,
                iconColor: const Color(0xFF246BFD),
                iconBackground: const Color(0xFFE3EDFF),
                title: 'My\nClasses',
                subtitle: '7 Active',
                onTap: () => onNavigate(1),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _QuickActionCard(
                icon: Icons.assignment_outlined,
                iconColor: const Color(0xFFFFA000),
                iconBackground: const Color(0xFFFFF2D7),
                title: 'Homeworks',
                subtitle: '5 Pending',
                onTap: () => onNavigate(2),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.calendar_today_outlined,
                iconColor: const Color(0xFF16B981),
                iconBackground: const Color(0xFFDDF8EE),
                title: 'Attendance',
                subtitle: '100% Tracked',

                // ATTENDANCE NAVIGATION
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AttendanceScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _QuickActionCard(
                icon: Icons.chat_bubble_outline,
                iconColor: const Color(0xFF8A5CFF),
                iconBackground: const Color(0xFFEDE5FF),
                title: 'Messages',
                subtitle: '12 New',
                onTap: () => onNavigate(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            "Today's Schedule",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF172033),
            ),
          ),
        ),

        TextButton(
          onPressed: () {},
          child: const Text(
            'See All',
            style: TextStyle(
              color: Color(0xFF246BFD),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 78,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 21),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF172033),
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8A91A0),
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                size: 19,
                color: Color(0xFF737B8C),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final String time;
  final String grade;
  final String subject;

  const _ScheduleCard({
    required this.time,
    required this.grade,
    required this.subject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 35,
            decoration: BoxDecoration(
              color: const Color(0xFF246BFD),
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(width: 10),

          SizedBox(
            width: 62,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Class Hour',
                  style: TextStyle(fontSize: 10, color: Color(0xFF8A91A0)),
                ),
              ],
            ),
          ),

          Container(width: 1, height: 35, color: const Color(0xFFE8EAF0)),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  grade,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A91A0),
                  ),
                ),
              ],
            ),
          ),

          const Icon(Icons.chevron_right, size: 20, color: Color(0xFF737B8C)),
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
