import 'package:flutter/material.dart';

import '../../homework_announcements/student/student_homework_screen.dart'
    show subjectIcon;
import '../models/mark_record.dart';
import '../models/results_overview.dart';
import 'mark_badge_field.dart' show MarkColors;

/// Term 1 / 2 / 3 switch shared by the student and parent screens.
class TermSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const TermSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

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

/// "▲ 4.2" / "▼ 3" / "same" for a change since the previous term.
class ChangeText extends StatelessWidget {
  /// An int (subject marks) or a double (averages).
  final num change;
  final bool onDark;
  final double fontSize;

  const ChangeText({
    super.key,
    required this.change,
    this.onDark = false,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    final up = onDark ? const Color(0xFF86EFAC) : const Color(0xFF16A34A);
    final down = onDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
    final flat = onDark ? Colors.white70 : const Color(0xFF6B7280);

    final value = change.abs();
    final same = change is int ? change == 0 : value < 0.05;
    final text = same
        ? 'same'
        : '${change > 0 ? '▲' : '▼'} ${change is int ? value : value.toStringAsFixed(1)}';
    return Text(
      text,
      style: TextStyle(
        color: same ? flat : (change > 0 ? up : down),
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Blue summary card: average, subject count, overall grade and best subject.
class OverallCard extends StatelessWidget {
  final ResultsOverview overview;

  /// Heading, e.g. "Term 2 average" or "Amaya's Term 2 average".
  final String title;

  /// Change in average since [previousTerm]; hidden when null.
  final double? change;
  final int? previousTerm;

  const OverallCard({
    super.key,
    required this.overview,
    required this.title,
    this.change,
    this.previousTerm,
  });

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
                      title,
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
          if (change != null && previousTerm != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                ChangeText(change: change!, onDark: true, fontSize: 13),
                Text(
                  '  vs Term $previousTerm',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ],
          if (best != null) ...[
            SizedBox(height: change != null ? 4 : 12),
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

/// One subject: icon, progress bar, mark and grade (plus change when known).
class SubjectResultCard extends StatelessWidget {
  final MarkRecord record;

  /// Change in this subject's mark since the previous term; hidden when null.
  final int? change;
  final VoidCallback? onTap;

  const SubjectResultCard({
    super.key,
    required this.record,
    this.change,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final band = MarkGrading.bandFor(record.mark);
    final colors = MarkColors.of(band);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
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
                            widthFactor: (record.mark / MarkGrading.maxMark)
                                .clamp(0.0, 1.0),
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
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
                  if (change != null) ChangeText(change: change!),
                ],
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showSubjectAnalysis(
  BuildContext context, {
  required String subject,
  required int selectedTerm,
  required Iterable<MarkRecord> allMarks,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _SubjectAnalysisSheet(
      subject: subject,
      selectedTerm: selectedTerm,
      marks: allMarks
          .where(
            (mark) =>
                mark.subject.trim().toLowerCase() ==
                subject.trim().toLowerCase(),
          )
          .toList(),
    ),
  );
}

class _SubjectAnalysisSheet extends StatelessWidget {
  final String subject;
  final int selectedTerm;
  final List<MarkRecord> marks;

  const _SubjectAnalysisSheet({
    required this.subject,
    required this.selectedTerm,
    required this.marks,
  });

  MarkRecord? _forTerm(int term) {
    for (final record in marks) {
      if (record.term == term) return record;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final values = marks.map((mark) => mark.mark).toList();
    final average = values.isEmpty
        ? 0
        : values.reduce((a, b) => a + b) / values.length;
    final highest = values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    final lowest = values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$subject analysis',
              style: const TextStyle(
                color: Color(0xFF17212F),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Term $selectedTerm selected · ${marks.length} term${marks.length == 1 ? '' : 's'} available',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (marks.isEmpty)
              const ResultsEmptyState(
                message: 'No marks recorded for this subject yet.',
              )
            else ...[
              Row(
                children: [
                  _AnalysisStat(
                    label: 'Average',
                    value: average.toStringAsFixed(1),
                  ),
                  const SizedBox(width: 8),
                  _AnalysisStat(label: 'Highest', value: '$highest'),
                  const SizedBox(width: 8),
                  _AnalysisStat(label: 'Lowest', value: '$lowest'),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Term-by-term marks',
                style: TextStyle(
                  color: Color(0xFF17212F),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final term in [1, 2, 3])
                _AnalysisTermRow(term: term, record: _forTerm(term)),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnalysisStat extends StatelessWidget {
  final String label;
  final String value;

  const _AnalysisStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF17212F),
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _AnalysisTermRow extends StatelessWidget {
  final int term;
  final MarkRecord? record;

  const _AnalysisTermRow({required this.term, required this.record});

  @override
  Widget build(BuildContext context) {
    final colors = record == null
        ? MarkColors.empty
        : MarkColors.of(MarkGrading.bandFor(record!.mark));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Term $term',
              style: const TextStyle(
                color: Color(0xFF17212F),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              record == null ? 'Not entered' : '${record!.mark} / 100',
              style: TextStyle(
                color: colors.fg,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResultsEmptyState extends StatelessWidget {
  final String message;

  const ResultsEmptyState({super.key, required this.message});

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
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}
