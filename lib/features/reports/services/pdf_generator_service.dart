import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/pdf_downloader/pdf_downloader.dart';
import '../../user_management/models/user_item.dart';

class PdfGeneratorService {
  static final PdfGeneratorService _instance = PdfGeneratorService._internal();
  factory PdfGeneratorService() => _instance;
  PdfGeneratorService._internal();

  /// Helper to build a clean two-column key-value row for PDF
  pw.Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9.5,
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.isNotEmpty ? value : '-',
              style: pw.TextStyle(
                fontSize: 9.5,
                color: isHighlight ? PdfColors.blue800 : PdfColors.black,
                fontWeight: isHighlight ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a prominent, highlighted credential box for login details & passwords
  pw.Widget _buildCredentialBox({
    required String roleLabel,
    required String email,
    required String password,
    PdfColor bgColor = PdfColors.blue50,
    PdfColor borderColor = PdfColors.blue300,
    PdfColor textColor = PdfColors.blue900,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 6),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: bgColor,
        border: pw.Border.all(color: borderColor, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 5,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '$roleLabel SIGN-IN EMAIL',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  email.isNotEmpty ? email : '-',
                  style: pw.TextStyle(
                    fontSize: 10.5,
                    fontWeight: pw.FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            width: 1,
            height: 26,
            color: borderColor,
            margin: const pw.EdgeInsets.symmetric(horizontal: 8),
          ),
          pw.Expanded(
            flex: 4,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '$roleLabel LOGIN PASSWORD',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  password.isNotEmpty ? password : '-',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a section card with a clean header
  pw.Widget _buildSectionCard({
    required String title,
    required List<pw.Widget> children,
    PdfColor accentColor = PdfColors.blue700,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: PdfColors.grey100,
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 10.5,
                fontWeight: pw.FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  /// Generates the official merged Student & Parent registration slip
  Future<Uint8List> generateStudentParentMergedPdf({
    required UserItem student,
    required String studentPassword,
    required UserItem parent,
    required String parentPassword,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Banner
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.blue800, width: 2),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SCHOOLBRIDGE ACADEMY',
                          style: pw.TextStyle(
                            fontSize: 17,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Student & Parent Registration & Account Credentials Slip',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey700,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue50,
                            border: pw.Border.all(color: PdfColors.blue400),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            'ADMISSION NO: ${student.admissionNo}',
                            style: pw.TextStyle(
                              fontSize: 10.5,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Issued: ${student.joinedDate}',
                          style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // Student Details Section
              _buildSectionCard(
                title: 'STUDENT PROFILE & ACCESS CREDENTIALS',
                children: [
                  _buildInfoRow('Full Name:', student.name),
                  _buildInfoRow('Admission / Index No:', student.admissionNo, isHighlight: true),
                  _buildInfoRow('Class / Grade:', student.gradeOrClass),
                  _buildInfoRow('Student Login Email:', student.email, isHighlight: true),
                  _buildInfoRow('Student Login Password:', studentPassword, isHighlight: true),
                  _buildInfoRow('Student Mobile:', student.phone),
                  _buildInfoRow('Home Phone (Landline):', student.homePhone),
                  if (student.dob.isNotEmpty) _buildInfoRow('Date of Birth:', student.dob),
                  if (student.gender.isNotEmpty) _buildInfoRow('Gender:', student.gender),
                  if (student.address.isNotEmpty) _buildInfoRow('Home Address:', student.address),
                  // Prominently Highlighted Student Credentials Box
                  _buildCredentialBox(
                    roleLabel: 'STUDENT',
                    email: student.email,
                    password: studentPassword,
                    bgColor: PdfColors.blue50,
                    borderColor: PdfColors.blue300,
                    textColor: PdfColors.blue900,
                  ),
                ],
              ),

              // Parent Details Section
              _buildSectionCard(
                title: 'PARENT / GUARDIAN PROFILE & ACCESS CREDENTIALS',
                accentColor: PdfColors.green800,
                children: [
                  _buildInfoRow('Parent Full Name:', parent.name),
                  _buildInfoRow('Relationship to Student:', parent.gradeOrClass),
                  _buildInfoRow('Parent Login Email:', parent.email, isHighlight: true),
                  _buildInfoRow('Parent Login Password:', parentPassword, isHighlight: true),
                  _buildInfoRow('Primary Mobile Phone:', parent.phone),
                  if (parent.homePhone.isNotEmpty)
                    _buildInfoRow('Home Phone (Landline):', parent.homePhone),
                  if (parent.nic.isNotEmpty) _buildInfoRow('NIC / ID Number:', parent.nic),
                  if (parent.occupation.isNotEmpty) _buildInfoRow('Occupation:', parent.occupation),
                  // Prominently Highlighted Parent Credentials Box
                  _buildCredentialBox(
                    roleLabel: 'PARENT',
                    email: parent.email,
                    password: parentPassword,
                    bgColor: PdfColors.green50,
                    borderColor: PdfColors.green300,
                    textColor: PdfColors.green900,
                  ),
                ],
              ),

              // Notice
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                margin: const pw.EdgeInsets.only(bottom: 8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  border: pw.Border.all(color: PdfColors.amber400),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('NOTE: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5, color: PdfColors.amber900)),
                    pw.Expanded(
                      child: pw.Text(
                        'Please preserve this slip securely. Use the respective Login Email and Password to log into SchoolBridge. Users are advised to change their temporary passwords after the initial sign-in.',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 160,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: PdfColors.grey700, width: 1),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'School Administrator / Registrar',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 160,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: PdfColors.grey700, width: 1),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Parent / Guardian Signature',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'SchoolBridge Integrated School Management System - Confidential',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generates registration slip for single user (Teacher / Admin)
  Future<Uint8List> generateSingleUserPdf({
    required UserItem user,
    required String password,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 10),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.blue800, width: 2),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SCHOOLBRIDGE ACADEMY',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          '${user.role} Registration & Account Credentials',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey700,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue50,
                            border: pw.Border.all(color: PdfColors.blue400),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Text(
                            user.role.toUpperCase(),
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Joined: ${user.joinedDate}',
                          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 14),

              _buildSectionCard(
                title: 'ACCOUNT PROFILE & ACCESS CREDENTIALS',
                children: [
                  _buildInfoRow('Full Name:', user.name),
                  _buildInfoRow('Assigned Role:', user.role, isHighlight: true),
                  _buildInfoRow(
                    user.role == 'Teacher' ? 'Class Teacher Of:' : 'Department:',
                    user.gradeOrClass,
                  ),
                  _buildInfoRow('Mobile Phone:', user.phone),
                  if (user.homePhone.isNotEmpty)
                    _buildInfoRow('Home Phone:', user.homePhone),
                  if (user.address.isNotEmpty)
                    _buildInfoRow('Address:', user.address),
                  _buildInfoRow('Account Status:', user.status),
                  _buildCredentialBox(
                    roleLabel: user.role.toUpperCase(),
                    email: user.email,
                    password: password,
                  ),
                ],
              ),

              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                margin: const pw.EdgeInsets.only(bottom: 20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  border: pw.Border.all(color: PdfColors.blue300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Access Instructions:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '1. Open the SchoolBridge application or portal.\n'
                      '2. Select your account role (${user.role}).\n'
                      '3. Enter your Sign-in Email and the Generated Temporary Password shown above.\n'
                      '4. Change your password after your first successful sign-in.',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 170,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: PdfColors.grey700, width: 1),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Authorized Administrator',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 170,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(color: PdfColors.grey700, width: 1),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Employee / User Signature',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'SchoolBridge Integrated School Management System - Confidential',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Downloads student + parent registration slip as PDF
  Future<void> downloadStudentParentSlip({
    required UserItem student,
    required String studentPassword,
    required UserItem parent,
    required String parentPassword,
  }) async {
    final bytes = await generateStudentParentMergedPdf(
      student: student,
      studentPassword: studentPassword,
      parent: parent,
      parentPassword: parentPassword,
    );
    final cleanAdmission = student.admissionNo.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final filename = 'Registration_Slip_${cleanAdmission.isNotEmpty ? cleanAdmission : "Student"}.pdf';
    await downloadPdf(bytes, filename);
  }

  /// Downloads single user registration slip as PDF
  Future<void> downloadSingleUserSlip({
    required UserItem user,
    required String password,
  }) async {
    final bytes = await generateSingleUserPdf(user: user, password: password);
    final cleanName = user.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final filename = 'Credential_Slip_${user.role}_$cleanName.pdf';
    await downloadPdf(bytes, filename);
  }

  /// Downloads academic/performance summary report PDF
  Future<void> downloadAcademicReportPdf({
    required String title,
    required String term,
    required String grade,
    required Map<String, int> subjects,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SCHOOLBRIDGE ACADEMY',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Academic Performance Report - $title',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.blue800, thickness: 1.5),
              pw.SizedBox(height: 12),
              _buildSectionCard(
                title: 'REPORT OVERVIEW',
                children: [
                  _buildInfoRow('Academic Term:', term),
                  _buildInfoRow('Grade / Class:', grade),
                  _buildInfoRow('Total Students:', '32'),
                  _buildInfoRow('Average Pass Rate:', '84%', isHighlight: true),
                ],
              ),
              pw.SizedBox(height: 12),
              _buildSectionCard(
                title: 'SUBJECT BREAKDOWN',
                children: subjects.entries.map((e) {
                  return _buildInfoRow('${e.key}:', '${e.value}%', isHighlight: e.value >= 75);
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
    final bytes = await pdf.save();
    final cleanTitle = title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    await downloadPdf(bytes, 'Report_$cleanTitle.pdf');
  }
}
