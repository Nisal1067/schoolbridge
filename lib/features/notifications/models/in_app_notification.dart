import 'package:cloud_firestore/cloud_firestore.dart';

class InAppNotification {
  final String id;
  final String recipientId;
  final String title;
  final String body;
  final String type; // 'chat', 'announcement', 'homework'
  final String? relatedId; // e.g., chatId or announcementId
  final bool isRead;
  final DateTime createdAt;

  InAppNotification({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  factory InAppNotification.fromMap(Map<String, dynamic> map, String id) {
    return InAppNotification(
      id: id,
      recipientId: map['recipientId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? '',
      relatedId: map['relatedId'],
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'recipientId': recipientId,
      'title': title,
      'body': body,
      'type': type,
      if (relatedId != null) 'relatedId': relatedId,
      'isRead': isRead,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
