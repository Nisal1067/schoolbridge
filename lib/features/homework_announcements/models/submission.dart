import 'package:cloud_firestore/cloud_firestore.dart';

import 'attachment.dart';

/// A student's submission, stored at
/// `homework/{homeworkId}/submissions/{studentId}`.
///
/// Students create these (student side, built later). Teachers only read them
/// and mark them as reviewed.
class Submission {
  final String studentId;
  final String studentName;

  /// 'submitted' | 'reviewed'
  final String status;
  final String note;
  final String feedback;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  /// Files the student handed in (PDF / images).
  final List<Attachment> attachments;

  const Submission({
    required this.studentId,
    required this.studentName,
    required this.status,
    required this.note,
    required this.feedback,
    this.submittedAt,
    this.reviewedAt,
    this.attachments = const [],
  });

  bool get isReviewed => status == 'reviewed';

  /// Late when handed in after the end of the due date.
  bool isLate(DateTime dueDate) {
    final at = submittedAt;
    if (at == null) return false;
    final deadline = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
    ).add(const Duration(days: 1));
    return at.isAfter(deadline);
  }

  factory Submission.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    DateTime? date(dynamic v) => v is Timestamp ? v.toDate() : null;
    return Submission(
      studentId: map['studentId'] as String? ?? doc.id,
      studentName: map['studentName'] as String? ?? '',
      status: map['status'] as String? ?? 'submitted',
      note: map['note'] as String? ?? '',
      feedback: map['feedback'] as String? ?? '',
      submittedAt: date(map['submittedAt']),
      reviewedAt: date(map['reviewedAt']),
      attachments: Attachment.listFrom(map['attachments']),
    );
  }
}
