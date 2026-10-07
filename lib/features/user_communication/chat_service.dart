import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../attendance/services/attendance_service.dart';

class ChatService {
  final db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

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
          for (final parent in List<String>.from(doc['parentIds'] ?? [])) {
            result[parent] = {
              'schoolId': profile['schoolId'],
              'teacherId': uid,
              'parentId': parent,
              'studentId': student['id'],
              'classId': classroom['id'],
              'label': '${student['name']} - Parent',
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
        for (final teacher in teachers) {
          result[teacher] = {
            'schoolId': profile['schoolId'],
            'teacherId': teacher,
            'parentId': uid,
            'studentId': child['id'],
            'classId': child['classId'],
            'label':
                '${classroom['name']} - Teacher (${teacher.substring(0, teacher.length < 6 ? teacher.length : 6)})',
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
    return id;
  }

  Future<void> send(String id, String text, String messageId) async {
    final ref = db.collection('chats').doc(id);
    final batch = db.batch();
    batch.set(ref.collection('messages').doc(messageId), {
      'senderId': uid,
      'text': text.trim(),
      'sentAt': FieldValue.serverTimestamp(),
    });
    batch.update(ref, {
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
