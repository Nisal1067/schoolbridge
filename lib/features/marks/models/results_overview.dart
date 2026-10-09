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

  /// How much the average moved compared with [previous]. Null when either
  /// term has no marks.
  double? averageChange(ResultsOverview previous) =>
      isEmpty || previous.isEmpty ? null : average - previous.average;

  /// How much the mark for [subject] moved compared with [previous]. Null
  /// when the subject has no mark in one of the two terms.
  int? subjectChange(String subject, ResultsOverview previous) {
    final key = subject.trim().toLowerCase();
    MarkRecord? find(ResultsOverview o) {
      for (final m in o.subjects) {
        if (m.subject.trim().toLowerCase() == key) return m;
      }
      return null;
    }

    final now = find(this);
    final before = find(previous);
    return now == null || before == null ? null : now.mark - before.mark;
  }

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
