import 'package:flutter/material.dart';
import '../../announcements/services/announcement_service.dart';
import '../services/notification_service.dart';
import '../models/in_app_notification.dart';
import '../../announcements/models/announcement_item.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    final hr = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$month ${dt.day}, $hr:$min $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: Color(0xFF4F46E5)),
            tooltip: 'Mark all as read',
            onPressed: () {
              NotificationService().markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF10B981)),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<List<InAppNotification>>(
        stream: NotificationService().myNotifications,
        builder: (context, notifSnapshot) {
          return StreamBuilder<List<AnnouncementItem>>(
            stream: AnnouncementService().announcementsStream,
            builder: (context, annSnapshot) {
              
              if (notifSnapshot.connectionState == ConnectionState.waiting && 
                  annSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final notifications = notifSnapshot.data ?? [];
              final announcements = annSnapshot.data ?? [];

              // Combine into a single list of dynamic items
              final List<dynamic> combinedList = [...notifications, ...announcements];

              // Sort by date (descending)
              combinedList.sort((a, b) {
                DateTime dateA = a is InAppNotification ? a.createdAt : (a.createdAt ?? DateTime.now());
                DateTime dateB = b is InAppNotification ? b.createdAt : (b.createdAt ?? DateTime.now());
                return dateB.compareTo(dateA);
              });

              if (combinedList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_rounded, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No notifications yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: combinedList.length,
                itemBuilder: (context, index) {
                  final item = combinedList[index];

                  if (item is InAppNotification) {
                    return _buildNotificationTile(context, item);
                  } else if (item is AnnouncementItem) {
                    return _buildAnnouncementTile(context, item);
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, InAppNotification notification) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notification.isRead ? const Color(0xFFF1F5F9) : const Color(0xFFBFDBFE),
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: () {
          if (!notification.isRead) {
            NotificationService().markAsRead(notification.id);
          }
          // Navigate to related chat based on relatedId if needed
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: notification.type == 'chat' ? const Color(0xFFDBEAFE) : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            notification.type == 'chat' ? Icons.chat_bubble_rounded : Icons.notifications_rounded,
            color: notification.type == 'chat' ? const Color(0xFF2563EB) : const Color(0xFFD97706),
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
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementTile(BuildContext context, AnnouncementItem announcement) {
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
          child: const Icon(Icons.campaign_rounded, color: Color(0xFF7C3AED)),
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
              child: const Text('Announcement', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
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
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
