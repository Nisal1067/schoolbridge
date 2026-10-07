import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../dashboards/screens/admin_dashboard.dart';
import '../../dashboards/screens/parent_dashboard.dart';
import '../../dashboards/screens/student_dashboard.dart';
import '../../dashboards/screens/teacher_dashboard.dart';
import '../../features/attendance/attendance_screen.dart';
import '../../features/attendance/add_attendance_screen.dart';
import '../../features/attendance/models/attendance_record.dart';
import '../../features/attendance/parent_attendance_screen.dart';
import '../../features/attendance/parent_attendance_report_screen.dart';
import '../screens/login_screen.dart';

class SessionNavigation extends NavigatorObserver {
  static Future<void> _pending = Future.value();
  static void remember(String page, [Map<String, dynamic> data = const {}]) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _pending = _pending
        .then((_) async {
          final preferences = await SharedPreferences.getInstance();
          await preferences.setString(
            'last_page',
            jsonEncode({'uid': uid, 'page': page, 'data': data}),
          );
        })
        .catchError((Object _) {});
  }

  void _capture(Route<dynamic>? route) {
    if (route is! MaterialPageRoute || navigator == null) return;
    final page = route.builder(navigator!.context);
    if (page is TeacherDashboard) {
      remember('teacher', {'index': page.initialIndex});
    } else if (page is StudentDashboard) {
      remember('student', {'index': page.initialIndex});
    } else if (page is ParentDashboard) {
      remember('parent', {'index': page.initialIndex});
    } else if (page is AdminDashboard) {
      remember('admin');
    } else if (page is AttendanceScreen) {
      remember('attendance');
    } else if (page is AddAttendanceScreen) {
      remember('attendance_add', {
        'classroom': page.classroom == null
            ? null
            : {
                for (final key in [
                  'id',
                  'name',
                  'schoolId',
                  'teacherId',
                  'teacherIds',
                ])
                  if (page.classroom!.containsKey(key))
                    key: page.classroom![key],
              },
        'existing': page.existing
            .map(
              (r) => {
                'documentId': r.documentId,
                'studentId': r.studentId,
                'studentName': r.studentName,
                'classId': r.classId,
                'schoolId': r.schoolId,
                'teacherId': r.teacherId,
                'date': r.date.toIso8601String(),
                'status': r.status,
                'term': r.term,
              },
            )
            .toList(),
      });
    } else if (page is ParentAttendanceScreen) {
      remember('student_attendance');
    } else if (page is ParentAttendanceReportScreen) {
      remember('student_report', {
        'view': page.initialView,
        'studentId': page.initialStudentId,
      });
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _capture(route);
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _capture(newRoute);
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _capture(previousRoute);

  static Future<Widget> restore() async {
    // Wait for Firebase to restore its persisted browser session first.
    final user = await FirebaseAuth.instance.authStateChanges().first;
    if (user == null) return const LoginScreen();
    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get(const GetOptions(source: Source.server));
    final data = profile.data();
    final role = data?['role'];
    if (data?['active'] != true ||
        !['teacher', 'student', 'parent', 'admin', 'staff'].contains(role)) {
      await FirebaseAuth.instance.signOut();
      return const LoginScreen();
    }
    Map<String, dynamic> bookmark = {};
    try {
      final preferences = await SharedPreferences.getInstance();
      bookmark = jsonDecode(
        preferences.getString('last_page') ?? '{}',
      ) as Map<String, dynamic>;
      if (bookmark['uid'] != user.uid) bookmark = {};
    } catch (_) {
      bookmark = {};
    }
    final saved = Map<String, dynamic>.from(bookmark['data'] as Map? ?? {});
    final index = saved['index'] is int
        ? (saved['index'] as int).clamp(0, 4)
        : 0;
    if (role == 'teacher') {
      if (bookmark['page'] == 'attendance') return const AttendanceScreen();
      if (bookmark['page'] == 'attendance_add') {
        final records = (saved['existing'] as List? ?? []).map((r) {
          final map = Map<String, dynamic>.from(r as Map);
          map['date'] = Timestamp.fromDate(
            DateTime.parse(map['date'] as String),
          );
          return AttendanceRecord.fromMap(map);
        }).toList();
        return AddAttendanceScreen(
          classroom: saved['classroom'] == null
              ? null
              : Map<String, dynamic>.from(saved['classroom'] as Map),
          existing: records,
        );
      }
      return TeacherDashboard(initialIndex: index);
    }
    if (role == 'parent' || role == 'student') {
      if (bookmark['page'] == 'student_attendance') {
        return const ParentAttendanceScreen();
      }
      if (bookmark['page'] == 'student_report') {
        return ParentAttendanceReportScreen(
          initialView: (saved['view'] as int? ?? 0).clamp(0, 3),
          initialStudentId: saved['studentId'] as String?,
        );
      }
      return role == 'parent'
          ? ParentDashboard(initialIndex: index)
          : StudentDashboard(initialIndex: index);
    }
    return const AdminDashboard();
  }
}
