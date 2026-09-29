import 'package:flutter/material.dart';

import '../../models/user_role.dart';

class AttendanceScreen extends StatelessWidget {
  final UserRole role;

  const AttendanceScreen({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance',
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    child: Text(
                      '92%',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Attendance',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        'Current academic term',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Card(
            child: ListTile(
              leading:
                  Icon(Icons.check_circle),
              title: Text('Present'),
              trailing: Text('46'),
            ),
          ),

          const Card(
            child: ListTile(
              leading:
                  Icon(Icons.cancel_outlined),
              title: Text('Absent'),
              trailing: Text('3'),
            ),
          ),

          const Card(
            child: ListTile(
              leading:
                  Icon(Icons.access_time),
              title: Text('Late'),
              trailing: Text('1'),
            ),
          ),
        ],
      ),
    );
  }
}