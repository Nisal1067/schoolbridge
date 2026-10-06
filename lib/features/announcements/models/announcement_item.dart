import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementItem {
  final String id;
  final String title;
  final String category; // 'General', 'Academic', 'Events'
  final String timeAgo;
  final String audience;
  final String message;
  final bool sendNotification;
  final bool isEmergency;
  final DateTime? createdAt;

  const AnnouncementItem({
    required this.id,
    required this.title,
    required this.category,
    required this.timeAgo,
    this.audience = 'All',
    this.message = '',
    this.sendNotification = true,
    this.isEmergency = false,
    this.createdAt,
  });

  String get subtitle => '$category • $timeAgo';

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'audience': audience,
      'message': message,
      'sendNotification': sendNotification,
      'isEmergency': isEmergency,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory AnnouncementItem.fromMap(Map<String, dynamic> map, String id) {
    DateTime? date;
    if (map['createdAt'] is Timestamp) {
      date = (map['createdAt'] as Timestamp).toDate();
    }

    String computeTimeAgo(DateTime? dt) {
      if (dt == null) return map['timeAgo'] ?? 'Recently';
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      return '${diff.inDays} days ago';
    }

    return AnnouncementItem(
      id: id,
      title: map['title'] ?? '',
      category: map['category'] ?? 'General',
      timeAgo: computeTimeAgo(date),
      audience: map['audience'] ?? 'All',
      message: map['message'] ?? '',
      sendNotification: map['sendNotification'] ?? true,
      isEmergency: map['isEmergency'] ?? false,
      createdAt: date,
    );
  }
}
