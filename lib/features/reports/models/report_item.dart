import 'package:cloud_firestore/cloud_firestore.dart';

class ReportItem {
  final String id;
  final String title;
  final String reportType; // 'Academic', 'Attendance', 'Users'
  final String date;
  final String academicYear;
  final String term;
  final String grade;
  final String classId;
  final String subject;
  final int studentCount;
  final int averagePercentage;
  final int passRate;
  final Map<String, int> subjectBreakdown;
  final DateTime? createdAt;

  const ReportItem({
    required this.id,
    required this.title,
    required this.reportType,
    required this.date,
    this.academicYear = '2026',
    this.term = 'Term 1',
    this.grade = 'Grade 10',
    this.classId = '10-A',
    this.subject = 'Mathematics',
    this.studentCount = 32,
    this.averagePercentage = 68,
    this.passRate = 84,
    this.subjectBreakdown = const {
      'Mathematics': 78,
      'Science': 71,
      'English': 82,
    },
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'reportType': reportType,
      'date': date,
      'academicYear': academicYear,
      'term': term,
      'grade': grade,
      'classId': classId,
      'subject': subject,
      'studentCount': studentCount,
      'averagePercentage': averagePercentage,
      'passRate': passRate,
      'subjectBreakdown': subjectBreakdown,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory ReportItem.fromMap(Map<String, dynamic> map, String id) {
    DateTime? dt;
    if (map['createdAt'] is Timestamp) {
      dt = (map['createdAt'] as Timestamp).toDate();
    }

    Map<String, int> breakdown = {
      'Mathematics': 78,
      'Science': 71,
      'English': 82,
    };

    if (map['subjectBreakdown'] is Map) {
      final raw = map['subjectBreakdown'] as Map;
      breakdown = raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }

    return ReportItem(
      id: id,
      title: map['title'] ?? '',
      reportType: map['reportType'] ?? 'Academic',
      date: map['date'] ?? 'Recently',
      academicYear: map['academicYear'] ?? '2026',
      term: map['term'] ?? 'Term 1',
      grade: map['grade'] ?? 'Grade 10',
      classId: map['classId'] ?? '10-A',
      subject: map['subject'] ?? 'Mathematics',
      studentCount: (map['studentCount'] as num?)?.toInt() ?? 32,
      averagePercentage: (map['averagePercentage'] as num?)?.toInt() ?? 68,
      passRate: (map['passRate'] as num?)?.toInt() ?? 84,
      subjectBreakdown: breakdown,
      createdAt: dt,
    );
  }
}
