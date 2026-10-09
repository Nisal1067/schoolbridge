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

  const SubjectResultCard({super.key, required this.record, this.change});

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
              if (change != null) ChangeText(change: change!),
            ],
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
