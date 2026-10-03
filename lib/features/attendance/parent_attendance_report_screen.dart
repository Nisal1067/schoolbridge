import 'package:flutter/material.dart';

class ParentAttendanceReportScreen extends StatefulWidget {
  const ParentAttendanceReportScreen({super.key});

  @override
  State<ParentAttendanceReportScreen> createState() =>
      _ParentAttendanceReportScreenState();
}

class _ParentAttendanceReportScreenState
    extends State<ParentAttendanceReportScreen> {
  int selectedTerm = 0;

  final List<String> pattern = [
    'P',
    'P',
    'P',
    'A',
    'P',
    'P',
    'P',
    'P',
    'L',
    'P',
    'P',
    'A',
    'P',
    'P',
    'P',
    'P',
    'P',
    'P',
    'P',
    'P',
    'P',
    'P',
    'W',
    'W',
    'W',
    'W',
    'W',
    'W',
  ];

  final List<Map<String, String>> recentHistory = [
    {
      'date': 'Today, 24 Oct',
      'time': 'Thursday • 08:45 AM',
      'status': 'Present',
    },
    {
      'date': '23 Oct 2024',
      'time': 'Wednesday • 08:50 AM',
      'status': 'Present',
    },
    {'date': '22 Oct 2024', 'time': 'Tuesday • 09:12 AM', 'status': 'Late'},
    {'date': '21 Oct 2024', 'time': 'Monday • 08:47 AM', 'status': 'Present'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Color(0xFF16B981),
          ),
        ),
        title: const Text(
          'Attendance',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFE8FAF3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.file_download_outlined,
                color: Color(0xFF16B981),
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
          child: Column(
            children: [
              _buildTermSelector(),

              const SizedBox(height: 28),

              _buildOverallCard(),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      icon: Icons.check_circle_outline,
                      title: 'Present',
                      value: '138',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      icon: Icons.cancel_outlined,
                      title: 'Absent',
                      value: '10',
                      color: const Color(0xFFF43F5E),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      icon: Icons.access_time,
                      title: 'Late',
                      value: '2',
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      icon: Icons.calendar_month_outlined,
                      title: 'Total Days',
                      value: '150',
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _buildPatternCard(),

              const SizedBox(height: 16),

              _buildRecentHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermSelector() {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD7E9E3)),
      ),
      child: Row(
        children: [
          _termButton('Term 1', 0),
          _termButton('Term 2', 1),
          _termButton('Term 3', 2),
        ],
      ),
    );
  }

  Widget _termButton(String text, int index) {
    final selected = selectedTerm == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedTerm = index;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF10B981) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverallCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFDCEBE6)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 145,
                  height: 145,
                  child: CircularProgressIndicator(
                    value: 0.92,
                    strokeWidth: 11,
                    backgroundColor: const Color(0xFFE8F7F2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF10B981),
                    ),
                  ),
                ),
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '92%',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Overall Rate',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE9FAF4),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('🔥', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '12-Day Active Streak',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  Text(
                    'Excellent! Sarah has attended 12 consecutive days of school.',
                    style: TextStyle(
                      height: 1.3,
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCEBE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),

              const Spacer(),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),

          const Spacer(),

          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternCard() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCEBE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'October Pattern',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Attendance trends at a glance',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),

              TextButton(
                onPressed: () {},
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Detail',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Color(0xFF10B981),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days
                .map(
                  (day) => SizedBox(
                    width: 28,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8190A5),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 10),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pattern.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              return _patternBox(pattern[index]);
            },
          ),

          const SizedBox(height: 14),

          const Divider(color: Color(0xFFDCEBE6)),

          const SizedBox(height: 4),

          const Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _Legend(color: Color(0xFF10B981), text: 'Present'),
              _Legend(color: Color(0xFFF43F5E), text: 'Absent'),
              _Legend(color: Color(0xFFF59E0B), text: 'Late'),
              _Legend(color: Color(0xFFF1F8F5), text: 'Weekend'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _patternBox(String status) {
    Color color;

    switch (status) {
      case 'P':
        color = const Color(0xFF10B981);
        break;

      case 'A':
        color = const Color(0xFFF43F5E);
        break;

      case 'L':
        color = const Color(0xFFF59E0B);
        break;

      default:
        color = const Color(0xFFF1F8F5);
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: status == 'W'
            ? Border.all(color: const Color(0xFFDDEDE7))
            : null,
      ),
    );
  }

  Widget _buildRecentHistory() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),

            TextButton(
              onPressed: () {},
              child: const Text(
                'View calendar',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFDCEBE6)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentHistory.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFDCEBE6)),
            itemBuilder: (context, index) {
              final record = recentHistory[index];

              return _historyItem(
                date: record['date']!,
                time: record['time']!,
                status: record['status']!,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _historyItem({
    required String date,
    required String time,
    required String status,
  }) {
    Color color;
    Color background;

    if (status == 'Present') {
      color = const Color(0xFF10B981);
      background = const Color(0xFFE7FAF3);
    } else if (status == 'Absent') {
      color = const Color(0xFFF43F5E);
      background = const Color(0xFFFFEDF0);
    } else {
      color = const Color(0xFFF59E0B);
      background = const Color(0xFFFFF6DF);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: text == 'Weekend'
                ? Border.all(color: const Color(0xFFDDEDE7))
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}
