import 'package:cloud_firestore/cloud_firestore.dart';

enum AnnouncementPriority { normal, important, urgent }

class Announcement {
  final String? id;
  final String schoolId;
  final String teacherId;
  final String title;
  final String body;

  /// Label shown on the card chip, e.g. "All Students" or "Grade 10A".
  final String audience;

  /// 'all_students' | 'parents' | 'teachers' | 'class'
  final String audienceType;

  /// Only set when [audienceType] is 'class', otherwise ''.
  final String classId;
  final AnnouncementPriority priority;
  final DateTime publishAt;
  final DateTime createdAt;

  const Announcement({
    this.id,
    required this.schoolId,
    required this.teacherId,
    required this.title,
    required this.body,
    required this.audience,
    required this.audienceType,
    required this.classId,
    required this.priority,
    required this.publishAt,
    required this.createdAt,
  });

  bool get isScheduled => publishAt.isAfter(DateTime.now());

  factory Announcement.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    DateTime date(dynamic v) => v is Timestamp ? v.toDate() : DateTime.now();
    final priorityName = map['priority'] as String? ?? 'normal';
    return Announcement(
      id: doc.id,
      schoolId: map['schoolId'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      audience: map['audience'] as String? ?? '',
      audienceType: map['audienceType'] as String? ?? 'all_students',
      classId: map['classId'] as String? ?? '',
      priority: AnnouncementPriority.values.firstWhere(
        (p) => p.name == priorityName,
        orElse: () => AnnouncementPriority.normal,
      ),
      publishAt: date(map['publishAt']),
      createdAt: date(map['createdAt']),
    );
  }
}
