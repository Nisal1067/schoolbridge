import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_attachment_api.dart';

import 'dart:typed_data';
import 'dart:async';

import '../attendance/services/attendance_service.dart';

class ChatService {
  static String sendError(Object error) {
    if (error is AttachmentApiException) return error.message;
    if (error is TimeoutException) {
      return 'Upload timed out. Check the attachment server and your connection, then retry.';
    }
    if (error is FirebaseException) {
      switch (error.code) {
        case 'bucket-not-found':
        case 'project-not-found':
          return 'Firebase Storage is not set up. Ask your project admin to enable Storage.';
        case 'unauthorized':
        case 'permission-denied':
          return 'Attachment access denied. Check chat links and published Firestore rules.';
        case 'quota-exceeded':
          return 'Storage quota or billing limit reached. Contact your project admin.';
        case 'retry-limit-exceeded':
          return 'Upload could not connect. Check Storage setup and your connection.';
      }
    }
    return 'Not sent. Check your connection or permissions and retry.';
  }

  static const maxAttachmentSize = 10 * 1024 * 1024;
  static const attachmentTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'pdf': 'application/pdf',
    'txt': 'text/plain',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  };
  static String? attachmentError(String name, int size) {
    if (name.length > 255) return 'Choose a file with a shorter name.';
    if (!attachmentTypes.containsKey(name.split('.').last.toLowerCase())) {
      return 'Choose a JPG, PNG, PDF, TXT or DOCX file.';
    }
    if (size <= 0 || size > maxAttachmentSize) {
      return 'Choose a file under 10 MB.';
    }
    return null;
  }

  Future<void> discardAttachment(String chat, String message) =>
      ChatAttachmentApi.discard(chat, message);

  Future<Map<String, dynamic>> uploadAttachment(
    String chat,
    String message,
    String name,
    Uint8List bytes,
    void Function(double) onProgress,
  ) async {
    final error = attachmentError(name, bytes.length);
    if (error != null) throw ArgumentError(error);
    return ChatAttachmentApi.upload(chat, message, name, bytes, onProgress);
  }

  final db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<DocumentSnapshot<Map<String, dynamic>>> conversationPreferences() =>
      db.collection('users').doc(uid).snapshots();

  Future<void> deleteConversation(String id) =>
      db.collection('users').doc(uid).update({
        FieldPath(['deletedChats', id]): FieldValue.serverTimestamp(),
      });

  static bool isConversationHidden(dynamic deletedAt, dynamic lastMessageAt) =>
      deletedAt is Timestamp &&
      (lastMessageAt is! Timestamp || lastMessageAt.compareTo(deletedAt) <= 0);

  static String chatId(String teacher, String parent) =>
      '${Uri.encodeComponent(teacher)}_${Uri.encodeComponent(parent)}';

  Stream<QuerySnapshot<Map<String, dynamic>>> conversations() => db
      .collection('chats')
      .where('participantIds', arrayContains: uid)
      .snapshots();

  Future<List<Map<String, dynamic>>> contacts() async {
    final profile = (await db.collection('users').doc(uid).get()).data()!;
    final attendance = AttendanceService();
    final result = <String, Map<String, dynamic>>{};
    if (profile['role'] == 'teacher') {
      for (final classroom in await attendance.teacherClasses()) {
        for (final student in await attendance.studentsForClass(classroom)) {
          final doc = (await db.collection('students').doc(student['id']).get())
              .data()!;
          for (final parentId in List<String>.from(doc['parentIds'] ?? [])) {
            final parentDoc = await db.collection('users').doc(parentId).get();
            final parentName = parentDoc.exists && parentDoc.data()?['name'] != null
                ? parentDoc.data()!['name']
                : 'Parent';
            result[parentId] = {
              'schoolId': profile['schoolId'],
              'teacherId': uid,
              'parentId': parentId,
              'studentId': student['id'],
              'classId': classroom['id'],
              'label': '${student['name']}\'s Parent ($parentName)',
            };
          }
        }
      }
    } else if (profile['role'] == 'parent') {
      for (final child in await attendance.linkedStudents()) {
        final classroom =
            (await db.collection('classes').doc(child['classId']).get()).data();
        if (classroom == null) continue;
        final teachers = <String>{
          ...List<String>.from(classroom['teacherIds'] ?? []),
          if ((classroom['teacherId'] as String? ?? '').isNotEmpty)
            classroom['teacherId'] as String,
        };
        for (final teacherId in teachers) {
          final teacherDoc = await db.collection('users').doc(teacherId).get();
          final teacherName = teacherDoc.exists && teacherDoc.data()?['name'] != null
              ? teacherDoc.data()!['name']
              : 'Teacher';
          result[teacherId] = {
            'schoolId': profile['schoolId'],
            'teacherId': teacherId,
            'parentId': uid,
            'studentId': child['id'],
            'classId': child['classId'],
            'label': '${classroom['name']} - $teacherName',
          };
        }
      }
    } else {
      throw StateError('Chat is available to teachers and parents only.');
    }
    return result.values.toList();
  }

  Future<String> start(Map<String, dynamic> contact) async {
    final id = chatId(contact['teacherId'], contact['parentId']);
    final ref = db.collection('chats').doc(id);
    await db.runTransaction((tx) async {
      final previous = await tx.get(ref);
      if (!previous.exists) {
        tx.set(ref, {
          for (final key in [
            'schoolId',
            'teacherId',
            'parentId',
            'studentId',
            'classId',
          ])
            key: contact[key],
          'participantIds': [contact['teacherId'], contact['parentId']],
          'lastMessage': '',
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
      }
    });
    await db.collection('users').doc(uid).update({
      FieldPath(['deletedChats', id]): FieldValue.delete(),
    });
    return id;
  }

  Future<void> send(
    String id,
    String text,
    String messageId, {
    Map<String, dynamic>? attachment,
  }) async {
    final ref = db.collection('chats').doc(id);
    final batch = db.batch();
    batch.set(ref.collection('messages').doc(messageId), {
      'senderId': uid,
      'text': text.trim(),
      'sentAt': FieldValue.serverTimestamp(),
      'attachment': ?attachment,
    });
    batch.update(ref, {
      'lastMessage': text.trim().isNotEmpty
          ? text.trim()
          : 'Attachment: ${attachment!['name']}',
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
