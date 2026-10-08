import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../attendance/services/attendance_service.dart';
import '../models/announcement.dart';
import '../models/attachment.dart';
import '../models/homework.dart';
import '../models/student_homework.dart';
import '../models/submission.dart';
import 'attachment_service.dart';

/// Shows a service message (e.g. "Please sign in again.") or a fallback.
String friendlyError(Object error, String fallback) {
  if (error is StateError) return error.message;
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to save this homework.';
      case 'unavailable':
      case 'deadline-exceeded':
        return 'The school database is unavailable. Check your connection and try again.';
      case 'unauthenticated':
        return 'Your session has expired. Please sign in again.';
      default:
        return error.message ?? fallback;
    }
  }
  return fallback;
}

/// Firestore access for the student side of homework and announcements.
///
/// Every stream returned here can only be listened to once, so create it in
/// `initState` (or when a tab opens) and not inside `build`.
class StudentHomeworkService {
  final FirebaseFirestore _firestore;
  final AttendanceService _attendance;
  final AttachmentUploader _uploader;

  StudentHomeworkService({
    FirebaseFirestore? firestore,
    AttendanceService? attendance,
    AttachmentUploader? uploader,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _attendance = attendance ?? AttendanceService(),
       _uploader = uploader ?? AttachmentUploader();

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Please sign in again.');
    return uid;
  }

  /// The signed-in student's `students/{uid}` document (name, classId, ...).
  Future<Map<String, dynamic>> studentRecord() async {
    final students = await _attendance.linkedStudents();
    if (students.isEmpty) {
      throw StateError(
        'Your student profile was not found. Please contact your school.',
      );
    }
    return students.first;
  }

  // ---------------------------------------------------------------- Homework

  /// Homework for the student's class, each paired with the student's own
  /// submission. Pending work comes first (soonest due), then finished work.
  Stream<List<StudentHomework>> watchMyHomework() {
    late final StreamController<List<StudentHomework>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? listSub;
    final submissionSubs =
        <String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>{};
    final submissions = <String, Submission?>{};
    final loaded = <String>{};
    var items = <Homework>[];

    void emit() {
      if (controller.isClosed) return;
      // Wait until every submission has reported once, to avoid flicker.
      if (!items.every((h) => loaded.contains(h.id))) return;
      final result = [
        for (final h in items) StudentHomework(h, submissions[h.id]),
      ]..sort(_compare);
      controller.add(result);
    }

    Future<void> start() async {
      try {
        final student = await studentRecord();
        final uid = _uid;
        listSub = _firestore
            .collection('homework')
            .where('classId', isEqualTo: student['classId'])
            .where('schoolId', isEqualTo: student['schoolId'])
            .snapshots()
            .listen((snapshot) {
              items = snapshot.docs.map(Homework.fromDoc).toList();
              final ids = items.map((h) => h.id!).toSet();

              // Stop watching homework that was deleted.
              for (final stale
                  in submissionSubs.keys
                      .where((id) => !ids.contains(id))
                      .toList()) {
                submissionSubs.remove(stale)?.cancel();
                submissions.remove(stale);
                loaded.remove(stale);
              }
              // Start watching this student's submission for new homework.
              for (final id in ids) {
                if (submissionSubs.containsKey(id)) continue;
                submissionSubs[id] = _firestore
                    .collection('homework')
                    .doc(id)
                    .collection('submissions')
                    .doc(uid)
                    .snapshots()
                    .listen((doc) {
                      submissions[id] = doc.exists
                          ? Submission.fromDoc(doc)
                          : null;
                      loaded.add(id);
                      emit();
                    }, onError: controller.addError);
              }
              emit();
            }, onError: controller.addError);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    controller = StreamController<List<StudentHomework>>(
      onListen: start,
      onCancel: () async {
        await listSub?.cancel();
        for (final sub in submissionSubs.values) {
          await sub.cancel();
        }
        submissionSubs.clear();
      },
    );
    return controller.stream;
  }

  int _compare(StudentHomework a, StudentHomework b) {
    if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
    final byDue = a.homework.dueDate.compareTo(b.homework.dueDate);
    return a.isDone ? -byDue : byDue;
  }

  Stream<Homework?> watchHomework(String id) => _firestore
      .collection('homework')
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? Homework.fromDoc(doc) : null);

  Stream<Submission?> watchMySubmission(String homeworkId) => _firestore
      .collection('homework')
      .doc(homeworkId)
      .collection('submissions')
      .doc(_uid)
      .snapshots()
      .map((doc) => doc.exists ? Submission.fromDoc(doc) : null);

  /// First submission creates the record; later ones update the note, the
  /// files and the time.
  ///
  /// [keep] are the files already saved that the student wants to keep and
  /// [newFiles] are files chosen in this session. Saved files that are not in
  /// [keep] are deleted once the submission is stored.
  Future<void> submitHomework({
    required Homework homework,
    required String note,
    Submission? existing,
    List<Attachment> keep = const [],
    List<PickedAttachment> newFiles = const [],
  }) async {
    final uid = _uid;
    final ref = _firestore
        .collection('homework')
        .doc(homework.id)
        .collection('submissions')
        .doc(uid);
    final uploaded = await _uploader.uploadAll(
      folder: AttachmentUploader.submissionFolder(
        schoolId: homework.schoolId,
        homeworkId: homework.id!,
        studentId: uid,
      ),
      files: newFiles,
    );
    final attachments = [
      for (final file in [...keep, ...uploaded]) file.toMap(),
    ];
    try {
      if (existing != null) {
        await ref.update({
          'note': note.trim(),
          'attachments': attachments,
          'submittedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final student = await studentRecord();
        await ref.set({
          'studentId': uid,
          'studentName': student['name'],
          'status': 'submitted',
          'note': note.trim(),
          'attachments': attachments,
          'submittedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // Do not leave files behind for a submission that was not saved.
      await _uploader.deleteAll(uploaded);
      rethrow;
    }
    if (existing != null) {
      final keptPaths = keep.map((file) => file.path).toSet();
      await _uploader.deleteAll(
        existing.attachments.where((file) => !keptPaths.contains(file.path)),
      );
    }
  }

  // ----------------------------------------------------------- Announcements

  /// Announcements for all students plus those sent to the student's class,
  /// newest first. Scheduled ones are included; hide them with
  /// `Announcement.isScheduled` when showing the list.
  Stream<List<Announcement>> watchMyAnnouncements() {
    late final StreamController<List<Announcement>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? generalSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? classSub;
    List<Announcement>? general;
    List<Announcement>? forClass;

    void emit() {
      final g = general;
      final c = forClass;
      if (g == null || c == null || controller.isClosed) return;
      final all = [...g, ...c]
        ..sort((a, b) => b.publishAt.compareTo(a.publishAt));
      controller.add(all);
    }

    Future<void> start() async {
      try {
        final student = await studentRecord();
        final base = _firestore
            .collection('announcements')
            .where('schoolId', isEqualTo: student['schoolId']);
        generalSub = base
            .where('audienceType', isEqualTo: 'all_students')
            .snapshots()
            .listen((snapshot) {
              general = snapshot.docs.map(Announcement.fromDoc).toList();
              emit();
            }, onError: controller.addError);
        classSub = base
            .where('audienceType', isEqualTo: 'class')
            .where('classId', isEqualTo: student['classId'])
            .snapshots()
            .listen((snapshot) {
              forClass = snapshot.docs.map(Announcement.fromDoc).toList();
              emit();
            }, onError: controller.addError);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    controller = StreamController<List<Announcement>>(
      onListen: start,
      onCancel: () async {
        await generalSub?.cancel();
        await classSub?.cancel();
      },
    );
    return controller.stream;
  }
}
