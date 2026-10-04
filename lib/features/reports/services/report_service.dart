import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_item.dart';

class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;

  ReportService._internal() {
    _reports = List.from(_defaultReports);
    _streamController.add(List.unmodifiable(_reports));
    _initFirestoreListener();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final List<ReportItem> _defaultReports = [
    const ReportItem(
      id: '1',
      title: 'Term 1 Results',
      reportType: 'Academic',
      date: '12 Sep 2026',
      academicYear: '2026',
      term: 'Term 1',
      grade: 'Grade 10',
      classId: '10-A',
      subject: 'All Subjects',
      studentCount: 32,
      averagePercentage: 68,
      passRate: 84,
      subjectBreakdown: {
        'Mathematics': 78,
        'Science': 71,
        'English': 82,
      },
    ),
    const ReportItem(
      id: '2',
      title: 'Attendance Aug',
      reportType: 'Attendance',
      date: '05 Sep 2026',
      academicYear: '2026',
      term: 'Term 1',
      grade: 'Grade 10',
      classId: 'All Classes',
      subject: 'Attendance',
      studentCount: 320,
      averagePercentage: 94,
      passRate: 98,
      subjectBreakdown: {
        'Present': 94,
        'Late': 4,
        'Absent': 2,
      },
    ),
    const ReportItem(
      id: '3',
      title: 'User Summary',
      reportType: 'Users',
      date: '28 Aug 2026',
      academicYear: '2026',
      term: 'Term 1',
      grade: 'All Grades',
      classId: 'All Classes',
      subject: 'Accounts',
      studentCount: 357,
      averagePercentage: 98,
      passRate: 100,
      subjectBreakdown: {
        'Students': 320,
        'Teachers': 25,
        'Staff': 12,
      },
    ),
  ];

  List<ReportItem> _reports = [];
  final StreamController<List<ReportItem>> _streamController =
      StreamController<List<ReportItem>>.broadcast();

  Stream<List<ReportItem>> get reportsStream => _streamController.stream;

  List<ReportItem> get currentReports => List.unmodifiable(_reports);

  void _initFirestoreListener() {
    try {
      _firestore
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
        (snapshot) {
          if (snapshot.docs.isNotEmpty) {
            _reports = snapshot.docs.map((doc) {
              return ReportItem.fromMap(doc.data(), doc.id);
            }).toList();
            _streamController.add(List.unmodifiable(_reports));
          }
        },
        onError: (_) {
          // Graceful fallback to default in-memory reports
        },
      );
    } catch (_) {
      // Offline or initialization fallback
    }
  }

  Future<void> saveReport(ReportItem report) async {
    _reports.insert(0, report);
    _streamController.add(List.unmodifiable(_reports));

    try {
      final docRef = await _firestore.collection('reports').add(report.toMap());
      final index = _reports.indexOf(report);
      if (index != -1) {
        _reports[index] = ReportItem(
          id: docRef.id,
          title: report.title,
          reportType: report.reportType,
          date: report.date,
          academicYear: report.academicYear,
          term: report.term,
          grade: report.grade,
          classId: report.classId,
          subject: report.subject,
          studentCount: report.studentCount,
          averagePercentage: report.averagePercentage,
          passRate: report.passRate,
          subjectBreakdown: report.subjectBreakdown,
          createdAt: report.createdAt,
        );
        _streamController.add(List.unmodifiable(_reports));
      }
    } catch (_) {
      // Local state is preserved
    }
  }

  Future<void> deleteReport(String id) async {
    _reports.removeWhere((r) => r.id == id);
    _streamController.add(List.unmodifiable(_reports));

    try {
      await _firestore.collection('reports').doc(id).delete();
    } catch (_) {
      // Local state is preserved
    }
  }
}
