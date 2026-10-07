import 'package:cloud_firestore/cloud_firestore.dart';

class Homework {
  final String? id;
  final String schoolId;
  final String classId;
  final String className;
  final String teacherId;
  final String subject;
  final String title;
  final String description;
  final DateTime dueDate;
  final int totalStudents;
  final int submittedCount;
  final DateTime createdAt;

  const Homework({
    this.id,
    required this.schoolId,
    required this.classId,
    required this.className,
    required this.teacherId,
    required this.subject,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.totalStudents,
    required this.submittedCount,
    required this.createdAt,
  });

  /// Active until the end of the due date.
  bool get isActive {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !dueDate.isBefore(today);
  }

  int get pendingCount =>
      (totalStudents - submittedCount).clamp(0, totalStudents).toInt();

  double get progress =>
      totalStudents == 0 ? 0 : (submittedCount / totalStudents).clamp(0, 1);

  factory Homework.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    DateTime date(dynamic v) => v is Timestamp ? v.toDate() : DateTime.now();
    return Homework(
      id: doc.id,
      schoolId: map['schoolId'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      className: map['className'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      subject: map['subject'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      dueDate: date(map['dueDate']),
      totalStudents: (map['totalStudents'] as num?)?.toInt() ?? 0,
      submittedCount: (map['submittedCount'] as num?)?.toInt() ?? 0,
      createdAt: date(map['createdAt']),
    );
  }
}