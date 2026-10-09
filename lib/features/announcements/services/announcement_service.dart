import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement_item.dart';

class AnnouncementService {
  static final AnnouncementService _instance = AnnouncementService._internal();
  factory AnnouncementService() => _instance;

  AnnouncementService._internal() {
    _items = List.from(_defaultAnnouncements);
    _streamController.add(List.unmodifiable(_items));
    _initFirestoreListener();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final List<AnnouncementItem> _defaultAnnouncements = [
    const AnnouncementItem(
      id: '1',
      title: 'Term 1 Exam Schedule',
      category: 'Academic',
      timeAgo: '2 hours ago',
      message: 'Term 1 final examinations will commence on November 15th.',
    ),
    const AnnouncementItem(
      id: '2',
      title: 'School Sports Day',
      category: 'Events',
      timeAgo: '1 day ago',
      message: 'Annual inter-house sports meet scheduled for next Friday.',
    ),
    const AnnouncementItem(
      id: '3',
      title: 'Library Closed',
      category: 'General',
      timeAgo: '2 days ago',
      message: 'Main school library will be closed for system maintenance.',
    ),
    const AnnouncementItem(
      id: '4',
      title: 'New ICT Lab Opening',
      category: 'General',
      timeAgo: '3 days ago',
      message: 'The newly upgraded computer lab is now open for students.',
    ),
  ];

  List<AnnouncementItem> _items = [];
  final StreamController<List<AnnouncementItem>> _streamController =
      StreamController<List<AnnouncementItem>>.broadcast();

  Stream<List<AnnouncementItem>> get announcementsStream => _streamController.stream;

  List<AnnouncementItem> get currentAnnouncements => List.unmodifiable(_items);

  void _initFirestoreListener() {
    try {
      _firestore
          .collection('announcements')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            _items = snapshot.docs.map((doc) {
              return AnnouncementItem.fromMap(doc.data(), doc.id);
            }).toList();
            _streamController.add(List.unmodifiable(_items));
          }
        },
        onError: (_) {
          // Graceful fallback to default in-memory items
        },
      );
    } catch (_) {
      // Offline or initialization fallback
    }
  }

  Future<void> addAnnouncement(AnnouncementItem item) async {
    _items.insert(0, item);
    _streamController.add(List.unmodifiable(_items));

    try {
      final docRef = await _firestore.collection('announcements').add(item.toMap());
      // Update with generated ID
      final index = _items.indexOf(item);
      if (index != -1) {
        _items[index] = AnnouncementItem(
          id: docRef.id,
          title: item.title,
          category: item.category,
          timeAgo: item.timeAgo,
          audience: item.audience,
          message: item.message,
          sendNotification: item.sendNotification,
          isEmergency: item.isEmergency,
          createdAt: item.createdAt,
        );
        _streamController.add(List.unmodifiable(_items));
      }
    } catch (_) {
      // Local state is preserved
    }
  }

  Future<void> sendEmergencyAlert(String message) async {
    final alert = AnnouncementItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'EMERGENCY ALERT',
      category: 'General',
      timeAgo: 'Just now',
      audience: 'All',
      message: message,
      sendNotification: true,
      isEmergency: true,
      createdAt: DateTime.now(),
    );

    await addAnnouncement(alert);
  }

  Future<void> deleteAnnouncement(String id) async {
    _items.removeWhere((a) => a.id == id);
    _streamController.add(List.unmodifiable(_items));

    try {
      await _firestore.collection('announcements').doc(id).delete();
    } catch (_) {
      // Local state is preserved
    }
  }
}
