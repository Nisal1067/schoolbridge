import 'package:flutter/material.dart';

import '../models/mark_record.dart';
import 'mark_badge_field.dart';

/// Opens the class summary shown by the chart button next to "Save Marks".
Future<void> showMarksSummarySheet(
  BuildContext context, {
  required String className,
  required String subject,
  required MarkSummary summary,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MarksSummarySheet(
      className: className,
      subject: subject,
      summary: summary,
    ),
  );
}

class _MarksSummarySheet extends StatelessWidget {
  final String className;
  final String subject;
  final MarkSummary summary;

  const _MarksSummarySheet({
    required this.className,
    required this.subject,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final hasMarks = summary.entered > 0;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Class summary',
              style: TextStyle(
                color: Color(0xFF17212F),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$className · $subject',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (!hasMarks)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Enter some marks to see the summary.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  _Stat(
                    label: 'Average',
                    value: summary.average.toStringAsFixed(1),
                  ),
                  const SizedBox(width: 10),
                  _Stat(label: 'Pass rate', value: '${summary.passRate}%'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Stat(label: 'Highest', value: '${summary.highest}'),
                  const SizedBox(width: 10),
                  _Stat(label: 'Lowest', value: '${summary.lowest}'),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Grade distribution',
                style: TextStyle(
                  color: Color(0xFF17212F),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              for (final band in MarkBand.values)
                _BandBar(
                  band: band,
                  count: summary.distribution[band] ?? 0,
                  entered: summary.entered,
                ),
            ],
            const SizedBox(height: 12),
            Text(
              '${summary.entered} of ${summary.total} marks entered',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF17212F),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BandBar extends StatelessWidget {
  final MarkBand band;
  final int count;
  final int entered;

  const _BandBar({
    required this.band,
    required this.count,
    required this.entered,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MarkColors.of(band);
    final fraction = entered == 0 ? 0.0 : count / entered;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              MarkGrading.label(band),
              style: const TextStyle(color: Color(0xFF374151), fontSize: 12),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 10, color: const Color(0xFFF3F4F6)),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(height: 10, color: colors.fg),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF17212F),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
