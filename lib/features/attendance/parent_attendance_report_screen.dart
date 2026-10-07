import 'package:flutter/material.dart';

import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'widgets/attendance_navigation.dart';

import 'models/attendance_record.dart';
import 'widgets/student_attendance_view.dart';

class ParentAttendanceReportScreen extends StatefulWidget {
  final int initialView;
  final String? initialStudentId;
  const ParentAttendanceReportScreen({
    super.key,
    this.initialView = 0,
    this.initialStudentId,
  });

  @override
  State<ParentAttendanceReportScreen> createState() =>
      _ParentAttendanceReportScreenState();
}

class _ParentAttendanceReportScreenState
    extends State<ParentAttendanceReportScreen> {
  late int selectedView = widget.initialView;
  DateTime _currentMonth = DateTime.now();
  List<AttendanceRecord> _filtered = [];
  Map<String, int> _stats = AttendanceRecord.summary([]);
  String _studentName = '';
  List<String> pattern = [];
  List<Map<String, String>> recentHistory = [];
  int get _streak {
    int count = 0;
    for (final record in _filtered) {
      if (record.status == 'A') break;
      count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      bottomNavigationBar: AttendanceNavigation(),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Color(0xFF16B981),
          ),
        ),
        title: const Text(
          'Attendance',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFE8FAF3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _generateAndSavePDF,
              icon: const Icon(
                Icons.file_download_outlined,
                color: Color(0xFF16B981),
              ),
            ),
          ),
        ],
      ),

      body: StudentAttendanceView(
        initialStudentId: widget.initialStudentId,
        builder: (student, records) {
          _studentName = student['name'] as String;
          _filtered = records.where((r) {
            if (selectedView == 0) {
              return r.date.year == _currentMonth.year && r.date.month == _currentMonth.month;
            }
            return r.term == selectedView;
          }).toList();
          _stats = AttendanceRecord.summary(_filtered);
          final month = selectedView == 0
              ? _currentMonth
              : (_filtered.isEmpty ? DateTime.now() : _filtered.first.date);
          final marks = {
            for (final r in _filtered.where(
              (r) => r.date.year == month.year && r.date.month == month.month,
            ))
              r.date.day: r.status,
          };
          pattern = List.filled(
            DateTime(month.year, month.month, 1).weekday - 1,
            '',
            growable: true,
          );
          for (
            int day = 1;
            day <= DateTime(month.year, month.month + 1, 0).day;
            day++
          ) {
            pattern.add(
              marks[day] ??
                  (DateTime(month.year, month.month, day).weekday > 5
                      ? 'W'
                      : ''),
            );
          }
          recentHistory = _filtered
              .map(
                (r) => {
                  'date': '${r.date.year}-${r.date.month}-${r.date.day}',
                  'time': selectedView == 0 ? 'Monthly Record' : 'Term ${r.term}',
                  'status': r.status == 'P'
                      ? 'Present'
                      : r.status == 'A'
                      ? 'Absent'
                      : 'Late',
                },
              )
              .toList();
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
              child: Column(
                children: [
                  _buildTermSelector(),

                  if (selectedView == 0) ...[
                    const SizedBox(height: 20),
                    _buildMonthNavigation(),
                  ],

                  const SizedBox(height: 20),

                  _buildOverallCard(),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          icon: Icons.check_circle_outline,
                          title: 'Present',
                          value: '${_stats['present']}',
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          icon: Icons.cancel_outlined,
                          title: 'Absent',
                          value: '${_stats['absent']}',
                          color: const Color(0xFFF43F5E),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          icon: Icons.access_time,
                          title: 'Late',
                          value: '${_stats['late']}',
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          icon: Icons.calendar_month_outlined,
                          title: 'Total Days',
                          value: '${_stats['totalDays']}',
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildPatternCard(),

                  const SizedBox(height: 16),

                  if (_filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(selectedView == 0 ? 'No attendance recorded for this month.' : 'No attendance recorded for this term.'),
                    ),
                  _buildRecentHistory(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTermSelector() {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD7E9E3)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _termButton('This Month', 0),
          _termButton('Term 1', 1),
          _termButton('Term 2', 2),
          _termButton('Term 3', 3),
        ],
      ),
    );
  }

  Widget _termButton(String text, int index) {
    final selected = selectedView == index;

    return InkWell(
      onTap: () {
        setState(() {
          selectedView = index;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildOverallCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCEBE6)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 145,
                  height: 145,
                  child: CircularProgressIndicator(
                    value: _stats['attendance']! / 100,
                    strokeWidth: 11,
                    backgroundColor: const Color(0xFFE8F7F2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF10B981),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_stats['attendance']}%',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Overall Rate',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE9FAF4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department_outlined),
                      SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          '$_streak-Day Active Streak',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10),

                  Text(
                    '$_studentName has attended $_streak consecutive recorded school days.',
                    style: TextStyle(
                      height: 1.3,
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCEBE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),

              const Spacer(),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),

          const Spacer(),

          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternCard() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCEBE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance Pattern',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Attendance trends at a glance',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),

              TextButton(
                onPressed: () {},
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Text(
                    //   'Detail',
                    //   style: TextStyle(
                    //     fontSize: 12,
                    //     fontWeight: FontWeight.w600,
                    //     color: Color(0xFF10B981),
                    //   ),
                    // ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Color(0xFF10B981),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days
                .map(
                  (day) => SizedBox(
                    width: 28,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8190A5),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 10),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pattern.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              return _patternBox(pattern[index]);
            },
          ),

          const SizedBox(height: 14),

          const Divider(color: Color(0xFFDCEBE6)),

          const SizedBox(height: 4),

          const Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _Legend(color: Color(0xFF10B981), text: 'Present'),
              _Legend(color: Color(0xFFF43F5E), text: 'Absent'),
              _Legend(color: Color(0xFFF59E0B), text: 'Late'),
              _Legend(color: Color(0xFFF1F8F5), text: 'Weekend'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _patternBox(String status) {
    Color color;

    switch (status) {
      case 'P':
        color = const Color(0xFF10B981);
        break;

      case 'A':
        color = const Color(0xFFF43F5E);
        break;

      case 'L':
        color = const Color(0xFFF59E0B);
        break;

      default:
        color = const Color(0xFFF1F8F5);
    }

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: status == 'W'
            ? Border.all(color: const Color(0xFFDDEDE7))
            : null,
      ),
    );
  }

  Widget _buildRecentHistory() {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ),

            // TextButton(
            //   onPressed: () {},
            //   child: const Text(
            //     'View calendar',
            //     style: TextStyle(
            //       color: Color(0xFF10B981),
            //       fontSize: 12,
            //       fontWeight: FontWeight.w600,
            //     ),
            //   ),
            // ),
          ],
        ),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDCEBE6)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentHistory.length,
            separatorBuilder: (_, index) =>
                const Divider(height: 1, color: Color(0xFFDCEBE6)),
            itemBuilder: (context, index) {
              final record = recentHistory[index];

              return _historyItem(
                date: record['date']!,
                time: record['time']!,
                status: record['status']!,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _historyItem({
    required String date,
    required String time,
    required String status,
  }) {
    Color color;
    Color background;

    if (status == 'Present') {
      color = const Color(0xFF10B981);
      background = const Color(0xFFE7FAF3);
    } else if (status == 'Absent') {
      color = const Color(0xFFF43F5E);
      background = const Color(0xFFFFEDF0);
    } else {
      color = const Color(0xFFF59E0B);
      background = const Color(0xFFFFF6DF);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigation() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
            });
          },
          icon: const Icon(Icons.chevron_left, color: Color(0xFF64748B)),
        ),
        Text(
          '${months[_currentMonth.month - 1]} ${_currentMonth.year}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        Visibility(
          visible: !(_currentMonth.year == DateTime.now().year && _currentMonth.month == DateTime.now().month),
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: IconButton(
            onPressed: () {
              setState(() {
                _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
              });
            },
            icon: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }

  Future<void> _generateAndSavePDF() async {
    if (_studentName.isEmpty) return;

    try {
      final pdf = pw.Document();
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      String period = selectedView == 0
          ? '${months[_currentMonth.month - 1]} ${_currentMonth.year}'
          : 'Term $selectedView';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Attendance Report',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.SizedBox(height: 20),
                pw.Text('Student: $_studentName', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                pw.Text('Period: $period', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
                pw.SizedBox(height: 30),
                
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Overall Attendance: ${_stats['attendance'] ?? 0}%',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                      pw.Text('Active Streak: $_streak Days', style: pw.TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 15),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Text('Present: ${_stats['present'] ?? 0}', style: pw.TextStyle(color: PdfColors.green700)),
                    pw.Text('Absent: ${_stats['absent'] ?? 0}', style: pw.TextStyle(color: PdfColors.red700)),
                    pw.Text('Late: ${_stats['late'] ?? 0}', style: pw.TextStyle(color: PdfColors.orange700)),
                    pw.Text('Total Days: ${_stats['totalDays'] ?? 0}'),
                  ]
                ),

                pw.SizedBox(height: 40),
                pw.Text('Recent History', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 10),
                ...recentHistory.take(15).map((record) => pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        color: record['status'] == 'Present' 
                             ? PdfColors.green50 
                             : record['status'] == 'Absent' 
                             ? PdfColors.red50 
                             : PdfColors.orange50
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(record['date']!),
                          pw.Text(record['status']!, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ],
                      ),
                    )),
                    
                if (recentHistory.isEmpty)
                  pw.Text('No records found for this period.', style: const pw.TextStyle(color: PdfColors.grey600)),
              ],
            );
          },
        ),
      );

      Uint8List bytes = await pdf.save();
      await FileSaver.instance.saveFile(
        name: 'Attendance_Report_${_studentName.replaceAll(' ', '_')}',
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF downloaded successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: text == 'Weekend'
                ? Border.all(color: const Color(0xFFDDEDE7))
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}
