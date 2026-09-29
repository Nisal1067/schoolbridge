import 'package:flutter/material.dart';

import '../../models/user_role.dart';

class HomeworkAnnouncementsScreen
    extends StatelessWidget {
  final UserRole role;

  const HomeworkAnnouncementsScreen({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Homework & Announcements',
          ),
          bottom: const TabBar(
            tabs: [
              Tab(
                text: 'Homework',
              ),
              Tab(
                text: 'Announcements',
              ),
            ],
          ),
        ),

        body: const TabBarView(
          children: [
            HomeworkTab(),
            AnnouncementTab(),
          ],
        ),
      ),
    );
  }
}

class HomeworkTab extends StatelessWidget {
  const HomeworkTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Card(
          child: ListTile(
            leading:
                Icon(Icons.assignment),
            title:
                Text('Mathematics Exercise'),
            subtitle:
                Text('Due: 05 October'),
          ),
        ),

        Card(
          child: ListTile(
            leading:
                Icon(Icons.assignment),
            title:
                Text('Science Project'),
            subtitle:
                Text('Due: 10 October'),
          ),
        ),
      ],
    );
  }
}

class AnnouncementTab extends StatelessWidget {
  const AnnouncementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Card(
          child: ListTile(
            leading:
                Icon(Icons.campaign),
            title:
                Text('Term Test Timetable'),
            subtitle:
                Text('Updated today'),
          ),
        ),

        Card(
          child: ListTile(
            leading:
                Icon(Icons.campaign),
            title:
                Text('School Sports Day'),
            subtitle:
                Text('Updated yesterday'),
          ),
        ),
      ],
    );
  }
}