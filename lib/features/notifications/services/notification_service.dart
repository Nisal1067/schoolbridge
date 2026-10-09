import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/in_app_notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  // Listen to current user's notifications
  Stream<List<InAppNotification>> get myNotifications {
    if (uid == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InAppNotification.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Create a new notification for a specific user
  Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    final notification = InAppNotification(
      id: '',
      recipientId: recipientId,
      title: title,
      body: body,
      type: type,
      relatedId: relatedId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(recipientId)
        .collection('notifications')
        .add(notification.toMap());
  }

  // Send notification to multiple users (e.g. for announcements)
  Future<void> sendNotifications(
    List<String> recipientIds, {
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    final batch = _firestore.batch();

    for (final recipientId in recipientIds) {
      final docRef = _firestore
          .collection('users')
          .doc(recipientId)
          .collection('notifications')
          .doc();

      final notification = InAppNotification(
        id: '',
        recipientId: recipientId,
        title: title,
        body: body,
        type: type,
        relatedId: relatedId,
        isRead: false,
        createdAt: DateTime.now(),
      );

      batch.set(docRef, notification.toMap());
    }

    await batch.commit();
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (uid == null) return;
    final unreadQuery = await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in unreadQuery.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
