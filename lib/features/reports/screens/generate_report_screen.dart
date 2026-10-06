import 'package:flutter/material.dart';
import '../../user_management/widgets/custom_app_bar.dart';
import '../models/report_item.dart';
import '../services/report_service.dart';
import 'report_preview_screen.dart';

class GenerateReportScreen extends StatefulWidget {
  const GenerateReportScreen({super.key});

  @override
  State<GenerateReportScreen> createState() => _GenerateReportScreenState();
}

class _GenerateReportScreenState extends State<GenerateReportScreen> {
  final _reportTypeController = TextEditingController(text: 'Academic');
  final _academicYearController = TextEditingController(text: '2026');
  final _termController = TextEditingController(text: 'Term 1');
  final _gradeController = TextEditingController(text: 'Grade 10');
  final _classController = TextEditingController(text: '10-A');
  final _subjectController = TextEditingController(text: 'Mathematics');

  @override
  void dispose() {
    _reportTypeController.dispose();
    _academicYearController.dispose();
    _termController.dispose();
    _gradeController.dispose();
    _classController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1E293B),
        ),
        decoration: const InputDecoration(
          filled: false,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: const SchoolBridgeAppBar(
        title: 'Generate Report',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Report Type'),
                    _buildTextField(_reportTypeController),
                    const SizedBox(height: 18),

                    _buildFieldLabel('Academic Year'),
                    _buildTextField(_academicYearController),
                    const SizedBox(height: 18),

                    _buildFieldLabel('Term'),
                    _buildTextField(_termController),
                    const SizedBox(height: 18),

                    _buildFieldLabel('Grade'),
                    _buildTextField(_gradeController),
                    const SizedBox(height: 18),

                    _buildFieldLabel('Class'),
                    _buildTextField(_classController),
                    const SizedBox(height: 18),

                    _buildFieldLabel('Subject'),
                    _buildTextField(_subjectController),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Action: Generate Report
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final newReport = ReportItem(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: '${_gradeController.text} • ${_termController.text}',
                      reportType: _reportTypeController.text,
                      date: 'Today',
                      academicYear: _academicYearController.text,
                      term: _termController.text,
                      grade: _gradeController.text,
                      classId: _classController.text,
                      subject: _subjectController.text,
                      createdAt: DateTime.now(),
                    );

                    final navigator = Navigator.of(context);
                    await ReportService().saveReport(newReport);

                    if (!mounted) return;
                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => ReportPreviewScreen(
                          title: newReport.title,
                          term: newReport.term,
                          grade: newReport.grade,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Generate Report',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
