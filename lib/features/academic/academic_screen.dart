import 'package:flutter/material.dart';

import '../../models/user_role.dart';

class AcademicScreen extends StatelessWidget {
  final UserRole role;

  const AcademicScreen({
    super.key,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Academic Progress',
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SubjectCard(
            subject: 'Mathematics',
            mark: '85%',
            grade: 'A',
          ),

          _SubjectCard(
            subject: 'Science',
            mark: '78%',
            grade: 'B',
          ),

          _SubjectCard(
            subject: 'English',
            mark: '88%',
            grade: 'A',
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String subject;
  final String mark;
  final String grade;

  const _SubjectCard({
    required this.subject,
    required this.mark,
    required this.grade,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(grade),
        ),
        title: Text(subject),
        subtitle: Text(
          'Current mark: $mark',
        ),
        trailing:
            const Icon(Icons.chevron_right),
      ),
    );
  }
}