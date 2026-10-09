import 'package:flutter/material.dart';

import '../../attendance/models/attendance_record.dart';
import '../../homework_announcements/student/student_homework_screen.dart'
    show subjectIcon;
import '../models/mark_record.dart';
import '../models/results_overview.dart';
import '../services/student_marks_service.dart';
import '../widgets/mark_badge_field.dart' show MarkColors;

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
              _TermSelector(
                selected: _term,
                onChanged: (term) => setState(() => _term = term),
              ),
              const SizedBox(height: 16),
              if (overview.isEmpty)
                _EmptyState(term: _term)
              else ...[
                _OverallCard(overview: overview),
                const SizedBox(height: 16),
                for (final record in overview.subjects) ...[
                  _SubjectCard(record: record),
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

class _TermSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _TermSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (var term = 1; term <= 3; term++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(term),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: term == selected
                        ? const Color(0xFF2563EB)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Term $term',
                    style: TextStyle(
                      color: term == selected
                          ? Colors.white
                          : const Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OverallCard extends StatelessWidget {
  final ResultsOverview overview;

  const _OverallCard({required this.overview});

  @override
  Widget build(BuildContext context) {
    final best = overview.best;
    final count = overview.subjects.length;
    final letter = MarkGrading.bandFor(overview.average.round()).name
        .toUpperCase();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Term ${overview.term} average',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${overview.average.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      count == 1 ? '1 subject' : '$count subjects',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (best != null) ...[
            const SizedBox(height: 12),
            Text(
              'Highest: ${best.subject} · ${best.mark}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final MarkRecord record;

  const _SubjectCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final band = MarkGrading.bandFor(record.mark);
    final colors = MarkColors.of(band);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              subjectIcon(record.subject),
              color: colors.fg,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF17212F),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(height: 8, color: const Color(0xFFF3F4F6)),
                      FractionallySizedBox(
                        widthFactor: (record.mark / MarkGrading.maxMark).clamp(
                          0.0,
                          1.0,
                        ),
                        child: Container(height: 8, color: colors.fg),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${record.mark}',
                style: TextStyle(
                  color: colors.fg,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Grade ${band.name.toUpperCase()}',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final int term;

  const _EmptyState({required this.term});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.bar_chart_rounded,
            size: 40,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            'No results for Term $term yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
