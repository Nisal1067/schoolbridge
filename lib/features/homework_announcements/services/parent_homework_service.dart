import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../attendance/services/attendance_service.dart';
import '../models/announcement.dart';
import '../models/homework.dart';
import '../models/student_homework.dart';
import '../models/submission.dart';

/// Firestore access for the parent side of homework and announcements.
///
/// Parents only read. Homework is shown per child (class homework paired with
/// that child's own submission); announcements are the ones addressed to
/// parents, to all students, or to a child's class.
///
/// Every stream returned here can only be listened to once, so create it in
/// `initState` (or when the selected child changes), not inside `build`.
class ParentHomeworkService {
  final FirebaseFirestore _firestore;
  final AttendanceService _attendance;

  ParentHomeworkService({
    FirebaseFirestore? firestore,
    AttendanceService? attendance,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _attendance = attendance ?? AttendanceService();

  /// Children linked to the signed-in parent (`students.parentIds`), by name.
  Future<List<Map<String, dynamic>>> children() async {
    final list = await _attendance.linkedStudents();
    list.sort(
      (a, b) =>
          (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? ''),
    );
    return list;
  }

  // ---------------------------------------------------------------- Homework

  /// Homework for [child]'s class, each paired with the child's submission.
  /// Pending work comes first (soonest due), then finished work.
  Stream<List<StudentHomework>> watchChildHomework(Map<String, dynamic> child) {
    final studentId = child['id'] as String;
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

    controller = StreamController<List<StudentHomework>>(
      onListen: () {
        listSub = _firestore
            .collection('homework')
            .where('classId', isEqualTo: child['classId'])
            .where('schoolId', isEqualTo: child['schoolId'])
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
              // Start watching the child's submission for new homework.
              for (final id in ids) {
                if (submissionSubs.containsKey(id)) continue;
                submissionSubs[id] = _firestore
                    .collection('homework')
                    .doc(id)
                    .collection('submissions')
                    .doc(studentId)
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
      },
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

  Stream<Submission?> watchSubmission(String homeworkId, String studentId) =>
      _firestore
          .collection('homework')
          .doc(homeworkId)
          .collection('submissions')
          .doc(studentId)
          .snapshots()
          .map((doc) => doc.exists ? Submission.fromDoc(doc) : null);

  // ----------------------------------------------------------- Announcements

  /// Announcements a parent should see, newest first: those sent to parents,
  /// those sent to all students, and those sent to any child's class.
  /// Scheduled ones are included; hide them with `Announcement.isScheduled`.
  Stream<List<Announcement>> watchAnnouncements(
    List<Map<String, dynamic>> students,
  ) {
    late final StreamController<List<Announcement>> controller;
    final subs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
    List<Announcement>? forParents;
    List<Announcement>? forStudents;
    List<Announcement>? forClasses;

    void emit() {
      final p = forParents;
      final s = forStudents;
      final c = forClasses;
      if (p == null || s == null || c == null || controller.isClosed) return;
      final all = [...p, ...s, ...c]
        ..sort((a, b) => b.publishAt.compareTo(a.publishAt));
      controller.add(all);
    }

    final classIds = {
      for (final s in students)
        if ((s['classId'] as String? ?? '').isNotEmpty) s['classId'] as String,
    }.toList();

    Future<void> start() async {
      try {
        final user = await _attendance.profile();
        final base = _firestore
            .collection('announcements')
            .where('schoolId', isEqualTo: user['schoolId']);

        List<Announcement> parse(QuerySnapshot<Map<String, dynamic>> s) =>
            s.docs.map(Announcement.fromDoc).toList();

        subs.add(
          base.where('audienceType', isEqualTo: 'parents').snapshots().listen((
            snapshot,
          ) {
            forParents = parse(snapshot);
            emit();
          }, onError: controller.addError),
        );
        subs.add(
          base
              .where('audienceType', isEqualTo: 'all_students')
              .snapshots()
              .listen((snapshot) {
                forStudents = parse(snapshot);
                emit();
              }, onError: controller.addError),
        );
        if (classIds.isEmpty) {
          forClasses = const [];
          emit();
        } else {
          // whereIn accepts up to 30 values, far more than any parent has.
          subs.add(
            base
                .where('audienceType', isEqualTo: 'class')
                .where('classId', whereIn: classIds.take(30).toList())
                .snapshots()
                .listen((snapshot) {
                  forClasses = parse(snapshot);
                  emit();
                }, onError: controller.addError),
          );
        }
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    controller = StreamController<List<Announcement>>(
      onListen: start,
      onCancel: () async {
        for (final sub in subs) {
          await sub.cancel();
        }
        subs.clear();
      },
    );
    return controller.stream;
  }
}
