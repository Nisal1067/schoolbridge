import 'package:flutter/material.dart';

import '../services/parent_homework_service.dart';
import '../services/student_homework_service.dart' show friendlyError;
import '../widgets/task_widgets.dart';
import 'parent_announcements_tab.dart';
import 'parent_common.dart';
import 'parent_homework_tab.dart';

/// Parent view of homework and announcements (read-only).
///
/// Pushed from the parent dashboard. [initialTab] is 0 for Homework and 1 for
/// Announcements. The screen has its own Scaffold; to make it a bottom-nav tab
/// later, swap the Scaffold for a Column and drop the app bar.
class ParentHomeworkAnnouncementsScreen extends StatefulWidget {
  final int initialTab;
  const ParentHomeworkAnnouncementsScreen({super.key, this.initialTab = 0});

  @override
  State<ParentHomeworkAnnouncementsScreen> createState() =>
      _ParentHomeworkAnnouncementsScreenState();
}

class _ParentHomeworkAnnouncementsScreenState
    extends State<ParentHomeworkAnnouncementsScreen> {
  final _service = ParentHomeworkService();
  late Future<List<Map<String, dynamic>>> _students = _service.children();
  late int _tab = widget.initialTab.clamp(0, 1).toInt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaskColors.background,
      appBar: taskAppBar('Homework & Announcements'),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _students,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ParentMessage(
                friendlyError(
                  snapshot.error!,
                  'Could not load your children. Check your account links.',
                ),
                onRetry: () => setState(() => _students = _service.children()),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final students = snapshot.data!;
            if (students.isEmpty) {
              return const ParentMessage(
                'No linked student profile found. Please contact your '
                'school.',
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: TaskTabs(
                    labels: const ['Homework', 'Announcements'],
                    selected: _tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ),
                // IndexedStack keeps both tabs alive, so their Firestore
                // streams are opened once and switching tabs is instant.
                Expanded(
                  child: IndexedStack(
                    index: _tab,
                    children: [
                      ParentHomeworkTab(students: students),
                      ParentAnnouncementsTab(students: students),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
