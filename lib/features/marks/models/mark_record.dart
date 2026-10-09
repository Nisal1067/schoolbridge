import 'package:cloud_firestore/cloud_firestore.dart';

/// Grade bands used for the mark badge colours and the class summary.
enum MarkBand { a, b, c, s, w }

class MarkGrading {
  const MarkGrading._();

  static const int maxMark = 100;

  /// Lowest mark counted as a pass. Change here if your school differs.
  static const int passMark = 35;

  static MarkBand bandFor(int mark) {
    if (mark >= 75) return MarkBand.a;
    if (mark >= 65) return MarkBand.b;
    if (mark >= 50) return MarkBand.c;
    if (mark >= passMark) return MarkBand.s;
    return MarkBand.w;
  }

  static String label(MarkBand band) => switch (band) {
    MarkBand.a => 'A  (75–100)',
    MarkBand.b => 'B  (65–74)',
    MarkBand.c => 'C  (50–64)',
    MarkBand.s => 'S  (35–49)',
    MarkBand.w => 'W  (0–34)',
  };
}

/// One student's mark for one subject in one term.
class MarkRecord {
  final String studentId;
  final String studentName;
  final String classId;
  final String schoolId;
  final String teacherId;
  final String subject;
  final int term;
  final int mark;

  const MarkRecord({
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.schoolId,
    required this.teacherId,
    required this.subject,
    required this.term,
    required this.mark,
  });

  /// Same school + class + subject + term + student always maps to the same
  /// document, so saving again updates the mark instead of duplicating it.
  static String buildId({
    required String schoolId,
    required String classId,
    required String subject,
    required int term,
    required String studentId,
  }) =>
      '${schoolId}_${classId}_${Uri.encodeComponent(subject.trim().toLowerCase())}'
      '_t${term}_$studentId';

  String get documentId => buildId(
    schoolId: schoolId,
    classId: classId,
    subject: subject,
    term: term,
    studentId: studentId,
  );

  Map<String, dynamic> toMap() => {
    'studentId': studentId,
    'studentName': studentName,
    'classId': classId,
    'schoolId': schoolId,
    'teacherId': teacherId,
    'subject': subject,
    'term': term,
    'mark': mark,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory MarkRecord.fromMap(Map<String, dynamic> map) => MarkRecord(
    studentId: map['studentId'] as String? ?? '',
    studentName: map['studentName'] as String? ?? '',
    classId: map['classId'] as String? ?? '',
    schoolId: map['schoolId'] as String? ?? '',
    teacherId: map['teacherId'] as String? ?? '',
    subject: map['subject'] as String? ?? '',
    term: (map['term'] as num?)?.toInt() ?? 1,
    mark: (map['mark'] as num?)?.toInt() ?? 0,
  );
}

/// Figures shown in the class summary sheet.
class MarkSummary {
  final int entered;
  final int total;
  final double average;
  final int highest;
  final int lowest;

  /// Percentage (0-100) of entered marks at or above [MarkGrading.passMark].
  final int passRate;
  final Map<MarkBand, int> distribution;

  const MarkSummary({
    required this.entered,
    required this.total,
    required this.average,
    required this.highest,
    required this.lowest,
    required this.passRate,
    required this.distribution,
  });

  factory MarkSummary.of(Iterable<int> marks, {required int totalStudents}) {
    final list = marks.toList();
    final distribution = {for (final band in MarkBand.values) band: 0};
    for (final mark in list) {
      final band = MarkGrading.bandFor(mark);
      distribution[band] = distribution[band]! + 1;
    }
    if (list.isEmpty) {
      return MarkSummary(
        entered: 0,
        total: totalStudents,
        average: 0,
        highest: 0,
        lowest: 0,
        passRate: 0,
        distribution: distribution,
      );
    }
    final passed = list.where((m) => m >= MarkGrading.passMark).length;
    return MarkSummary(
      entered: list.length,
      total: totalStudents,
      average: list.reduce((a, b) => a + b) / list.length,
      highest: list.reduce((a, b) => a > b ? a : b),
      lowest: list.reduce((a, b) => a < b ? a : b),
      passRate: (passed * 100 / list.length).round(),
      distribution: distribution,
    );
  }
}
