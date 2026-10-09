import 'package:flutter/material.dart';

import '../../attendance/models/attendance_record.dart';
import '../models/mark_record.dart';
import '../models/results_overview.dart';
import '../services/student_marks_service.dart';
import '../widgets/results_widgets.dart';

/// Student "Results" tab: marks per subject for a chosen term. Updates live
/// when a teacher saves marks. Shown inside the student dashboard, which
/// provides the top bar and bottom navigation.
class StudentResultsScreen extends StatefulWidget {
  const StudentResultsScreen({super.key});

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen> {
  static const _background = Color(0xFFF3F4F6);
  static const _ink = Color(0xFF17212F);

  final _service = StudentMarksService();
  late Stream<List<MarkRecord>> _marks = _service.watchMyMarks();
  int _term = AttendanceRecord.termForDate(DateTime.now());

  String _message(Object error) => error is StateError
      ? error.message
      : 'Could not load your results. Please try again.';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _background,
      child: StreamBuilder<List<MarkRecord>>(
        stream: _marks,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _message(snapshot.error!),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () =>
                          setState(() => _marks = _service.watchMyMarks()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final overview = ResultsOverview.forTerm(snapshot.data!, _term);
          final previous = _term > 1
              ? ResultsOverview.forTerm(snapshot.data!, _term - 1)
              : null;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              const Text(
                'Results',
                style: TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TermSelector(
                selected: _term,
                onChanged: (term) => setState(() => _term = term),
              ),
              const SizedBox(height: 16),
              if (overview.isEmpty)
                ResultsEmptyState(message: 'No results for Term $_term yet.')
              else ...[
                OverallCard(
                  overview: overview,
                  title: 'Term $_term average',
                  change: previous == null
                      ? null
                      : overview.averageChange(previous),
                  previousTerm: _term - 1,
                ),
                const SizedBox(height: 16),
                for (final record in overview.subjects) ...[
                  SubjectResultCard(
                    record: record,
                    change: previous == null
                        ? null
                        : overview.subjectChange(record.subject, previous),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
