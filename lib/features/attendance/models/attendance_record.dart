import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final String? id;
  final String studentId;
  final String studentName;
  final String classId;
  final String schoolId;
  final String teacherId;
  final DateTime date;
  final String status;
  final int term;

  const AttendanceRecord({
    this.id,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.schoolId,
    required this.teacherId,
    required this.date,
    required this.status,
    required this.term,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'schoolId': schoolId,
      'teacherId': teacherId,
      'date': Timestamp.fromDate(date),
      'status': status,
      'term': term,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  String get documentId =>
      id ??
      '${schoolId}_${classId}_${studentId}_${date.year}'
          '${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  static Map<String, int> summary(Iterable<AttendanceRecord> records) {
    final list = records.toList();
    final present = list.where((r) => r.status == 'P').length;
    final late = list.where((r) => r.status == 'L').length;
    return {
      'present': present,
      'absent': list.where((r) => r.status == 'A').length,
      'late': late,
      'totalDays': list.length,
      'attendance': list.isEmpty
          ? 0
          : ((present + late) * 100 / list.length).round(),
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    final timestamp = map['date'];

    return AttendanceRecord(
      id: map['documentId'] as String?,
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      schoolId: map['schoolId'] as String? ?? '',
      teacherId: map['teacherId'] as String? ?? '',
      date: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
      status: map['status'] as String? ?? '',
      term: (map['term'] as num?)?.toInt() ?? 1,
    );
  }
}
