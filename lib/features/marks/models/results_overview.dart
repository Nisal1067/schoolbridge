import 'mark_record.dart';

/// A student's marks for one term, ready to show on the Results tab.
class ResultsOverview {
  final int term;

  /// One entry per subject, sorted by subject name.
  final List<MarkRecord> subjects;

  /// Mean of all marks in [subjects] (0 when there are none).
  final double average;

  /// The subject with the highest mark, or null when there are no marks.
  final MarkRecord? best;

  const ResultsOverview({
    required this.term,
    required this.subjects,
    required this.average,
    required this.best,
  });

  bool get isEmpty => subjects.isEmpty;

  factory ResultsOverview.forTerm(Iterable<MarkRecord> all, int term) {
    final list = all.where((m) => m.term == term).toList()
      ..sort(
        (a, b) => a.subject.toLowerCase().compareTo(b.subject.toLowerCase()),
      );
    if (list.isEmpty) {
      return ResultsOverview(
        term: term,
        subjects: const [],
        average: 0,
        best: null,
      );
    }
    var best = list.first;
    var total = 0;
    for (final record in list) {
      total += record.mark;
      if (record.mark > best.mark) best = record;
    }
    return ResultsOverview(
      term: term,
      subjects: list,
      average: total / list.length,
      best: best,
    );
  }
}
