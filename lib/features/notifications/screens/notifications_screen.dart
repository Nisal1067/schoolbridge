import 'package:flutter/material.dart';

import '../../announcements/services/announcement_service.dart';
import '../services/notification_service.dart';
import '../models/in_app_notification.dart';
import '../../announcements/models/announcement_item.dart';
import '../../user_communication/chat_screen.dart';

class NotificationsScreen extends StatelessWidget {
  final bool onlyNotifications;

  const NotificationsScreen({super.key, this.onlyNotifications = false});

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dt.month - 1];
    final hr = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month ${dt.day}, $hr:$min $ampm';
  }

  Future<void> _openNotification(
    BuildContext context,
    InAppNotification notification,
  ) async {
    if (!notification.isRead) {
      await NotificationService().markAsRead(notification.id);
    }
    if (!context.mounted) return;

    if (notification.type == 'chat' &&
        (notification.relatedId ?? '').isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: notification.relatedId!,
            title: notification.title.replaceFirst('New message from ', ''),
          ),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Color(0xFF1E40AF)),
            tooltip: 'Mark all as read',
            onPressed: () {
              NotificationService().markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'All notifications marked as read',
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<InAppNotification>>(
        stream: NotificationService().myNotifications,
        builder: (context, notifSnapshot) {
          if (onlyNotifications) {
            if (!notifSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final notifications = notifSnapshot.data ?? [];
            if (notifications.isEmpty) {
              return _emptyNotifications();
            }
            return _buildNotificationHistory(context, notifications);
          }

          return StreamBuilder<List<AnnouncementItem>>(
            stream: AnnouncementService().announcementsStream,
            builder: (context, annSnapshot) {
              if (notifSnapshot.connectionState == ConnectionState.waiting &&
                  annSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final notifications = notifSnapshot.data ?? [];
              final announcements = annSnapshot.data ?? [];

              if (notifications.isEmpty && announcements.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off_rounded,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final unread = notifications.where((n) => !n.isRead).toList();
              final read = notifications.where((n) => n.isRead).toList();

              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  if (unread.isNotEmpty) _sectionHeader('Unread', unread.length),
                  for (final notification in unread)
                    _buildNotificationTile(context, notification),
                  if (read.isNotEmpty) _sectionHeader('Read', read.length),
                  for (final notification in read)
                    _buildNotificationTile(context, notification),
                  if (announcements.isNotEmpty)
                    _sectionHeader('Announcements', announcements.length),
                  for (final announcement in announcements)
                    _buildAnnouncementTile(context, announcement),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationHistory(
    BuildContext context,
    List<InAppNotification> notifications,
  ) {
    final unread = notifications.where((n) => !n.isRead).toList();
    final read = notifications.where((n) => n.isRead).toList();
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        if (unread.isNotEmpty) _sectionHeader('Unread', unread.length),
        for (final notification in unread)
          _buildNotificationTile(context, notification),
        if (read.isNotEmpty) _sectionHeader('Read', read.length),
        for (final notification in read)
          _buildNotificationTile(context, notification),
      ],
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    InAppNotification notification,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead
              ? const Color(0xFFF1F5F9)
              : const Color(0xFFBFDBFE),
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: () => _openNotification(context, notification),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: notification.type == 'chat'
                ? const Color(0xFFDBEAFE)
                : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            notification.type == 'chat'
                ? Icons.chat_bubble_rounded
                : Icons.notifications_rounded,
            color: notification.type == 'chat'
                ? const Color(0xFF2563EB)
                : const Color(0xFFD97706),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
            fontSize: 15,
            color: const Color(0xFF0F172A),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.body,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              _formatDate(notification.createdAt),
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementTile(
    BuildContext context,
    AnnouncementItem announcement,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.campaign_rounded, color: Color(0xFF1E40AF)),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                announcement.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Announcement',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              announcement.message,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              announcement.createdAt != null
                  ? _formatDate(announcement.createdAt!)
                  : announcement.timeAgo,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
