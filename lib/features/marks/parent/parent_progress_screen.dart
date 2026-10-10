import 'package:flutter/material.dart';

import '../../attendance/models/attendance_record.dart';
import '../../homework_announcements/parent/parent_common.dart' show firstName;
import '../models/mark_record.dart';
import '../models/results_overview.dart';
import '../services/student_marks_service.dart';
import '../widgets/results_widgets.dart';

/// Parent "Progress" tab: each linked child's marks per subject and term,
/// with the change since the previous term. Updates live when a teacher
/// saves marks. Shown inside the parent dashboard, which provides the top
/// bar and bottom navigation.
class ParentProgressScreen extends StatefulWidget {
  const ParentProgressScreen({super.key});

  @override
  State<ParentProgressScreen> createState() => _ParentProgressScreenState();
}

class _ParentProgressScreenState extends State<ParentProgressScreen> {
  static const _background = Color(0xFFF3F4F6);
  static const _ink = Color(0xFF17212F);
  static const _blue = Color(0xFF2563EB);

  final _service = StudentMarksService();
  late Future<List<Map<String, dynamic>>> _students = _service.linkedStudents();
  int _selected = 0;
  int _term = AttendanceRecord.termForDate(DateTime.now());
  Stream<List<MarkRecord>>? _marks;

  void _retry() => setState(() {
    _students = _service.linkedStudents();
    _marks = null;
    _selected = 0;
  });

  Widget _message(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _retry, child: const Text('Retry')),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _background,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _students,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _message(
              snapshot.error is StateError
                  ? (snapshot.error as StateError).message
                  : 'Could not load your children. Please try again.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final students = snapshot.data!;
          if (students.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No linked student profile found.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (_selected >= students.length) _selected = 0;
          final student = students[_selected];
          _marks ??= _service.watchStudentMarks(student);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _ChildHeader(
                students: students,
                selected: _selected,
                onSelect: (index) => setState(() {
                  _selected = index;
                  _marks = null;
                }),
              ),
              const SizedBox(height: 12),
              TermSelector(
                selected: _term,
                onChanged: (term) => setState(() => _term = term),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<MarkRecord>>(
                key: ValueKey(student['id']),
                stream: _marks,
                builder: (context, marks) {
                  if (marks.hasError) {
                    return const ResultsEmptyState(
                      message: 'Could not load marks. Please try again later.',
                    );
                  }
                  if (!marks.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return _buildResults(student, marks.data!);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResults(Map<String, dynamic> student, List<MarkRecord> all) {
    final overview = ResultsOverview.forTerm(all, _term);
    if (overview.isEmpty) {
      return ResultsEmptyState(
        message: 'No Term $_term marks for ${firstName(student)} yet.',
      );
    }
    final previous = _term > 1 ? ResultsOverview.forTerm(all, _term - 1) : null;
    final name = firstName(student);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OverallCard(
          overview: overview,
          title: "$name's Term $_term average",
          change: previous == null ? null : overview.averageChange(previous),
          previousTerm: _term - 1,
        ),
        const SizedBox(height: 16),
        for (final record in overview.subjects) ...[
          SubjectResultCard(
            record: record,
            change: previous == null
                ? null
                : overview.subjectChange(record.subject, previous),
            onTap: () => showSubjectAnalysis(
              context,
              subject: record.subject,
              selectedTerm: _term,
              allMarks: all,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

/// Child name and class for one child, or a chip row to switch between
/// several children.
class _ChildHeader extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  final int selected;
  final ValueChanged<int> onSelect;

  const _ChildHeader({
    required this.students,
    required this.selected,
    required this.onSelect,
  });

  String _className(Map<String, dynamic> student) {
    final name = (student['className'] as String? ?? '').trim();
    return name.isNotEmpty ? name : (student['classId'] as String? ?? '');
  }

  @override
  Widget build(BuildContext context) {
    if (students.length > 1) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < students.length; i++) ...[
              ChoiceChip(
                label: Text(firstName(students[i])),
                selected: i == selected,
                onSelected: (_) => onSelect(i),
                selectedColor: _ParentProgressScreenState._blue,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: i == selected ? Colors.white : const Color(0xFF17212F),
                  fontWeight: FontWeight.w600,
                ),
                showCheckmark: false,
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
      );
    }
    final student = students[selected];
    final className = _className(student);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.school_outlined, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              className.isEmpty
                  ? '${student['name']}'
                  : '${student['name']} · $className',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF17212F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
