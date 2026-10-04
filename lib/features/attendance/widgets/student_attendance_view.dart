import 'package:flutter/material.dart';

import '../models/attendance_record.dart';
import '../services/attendance_service.dart';

class StudentAttendanceView extends StatefulWidget {
  final Widget Function(Map<String, dynamic>, List<AttendanceRecord>) builder;
  final String? initialStudentId;
  const StudentAttendanceView({
    super.key,
    required this.builder,
    this.initialStudentId,
  });
  @override
  State<StudentAttendanceView> createState() => _StudentAttendanceViewState();
}

class _StudentAttendanceViewState extends State<StudentAttendanceView> {
  final _service = AttendanceService();
  late Future<List<Map<String, dynamic>>> _students = _service.linkedStudents();
  int _selected = 0;
  bool _initialSelected = false;
  Stream<List<AttendanceRecord>>? _records;

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _students,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _error(
          'Could not load student details. Check your account links.',
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final students = snapshot.data!;
      if (students.isEmpty) {
        return const Center(child: Text('No linked student profile found.'));
      }
      if (!_initialSelected) {
        final index = students.indexWhere(
          (s) => s['id'] == widget.initialStudentId,
        );
        if (index >= 0) _selected = index;
        _initialSelected = true;
      }
      final student = students[_selected];
      _records ??= _service.studentRecords(student);
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: students.length == 1
                ? Text(
                    '${student['name']} - ${student['classId']}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  )
                : DropdownButton<int>(
                    isExpanded: true,
                    value: _selected,
                    items: List.generate(
                      students.length,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text(students[i]['name'] as String),
                      ),
                    ),
                    onChanged: (value) => setState(() {
                      _selected = value!;
                      _records = null;
                    }),
                  ),
          ),
          Expanded(
            child: StreamBuilder<List<AttendanceRecord>>(
              key: ValueKey(student['id']),
              stream: _records,
              builder: (context, records) {
                if (records.hasError) {
                  return _error('Could not load attendance. Please retry.');
                }
                if (!records.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return widget.builder(student, records.data!);
              },
            ),
          ),
        ],
      );
    },
  );

  Widget _error(String message) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, textAlign: TextAlign.center),
        TextButton(
          onPressed: () => setState(() {
            _students = _service.linkedStudents();
            _records = null;
            _selected = 0;
            _initialSelected = false;
          }),
          child: const Text('Retry'),
        ),
      ],
    ),
  );
}
