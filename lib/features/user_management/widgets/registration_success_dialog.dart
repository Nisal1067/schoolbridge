import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../reports/services/pdf_generator_service.dart';
import '../models/user_item.dart';

class RegistrationSuccessDialog extends StatefulWidget {
  final bool isStudentParent;
  final UserItem? student;
  final String? studentPassword;
  final UserItem? parent;
  final String? parentPassword;

  // For single user
  final UserItem? singleUser;
  final String? singlePassword;

  const RegistrationSuccessDialog({
    super.key,
    required this.isStudentParent,
    this.student,
    this.studentPassword,
    this.parent,
    this.parentPassword,
    this.singleUser,
    this.singlePassword,
  });

  static Future<void> showStudentParent(
    BuildContext context, {
    required UserItem student,
    required String studentPassword,
    required UserItem parent,
    required String parentPassword,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RegistrationSuccessDialog(
        isStudentParent: true,
        student: student,
        studentPassword: studentPassword,
        parent: parent,
        parentPassword: parentPassword,
      ),
    );
  }

  static Future<void> showSingleUser(
    BuildContext context, {
    required UserItem user,
    required String password,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RegistrationSuccessDialog(
        isStudentParent: false,
        singleUser: user,
        singlePassword: password,
      ),
    );
  }

  @override
  State<RegistrationSuccessDialog> createState() =>
      _RegistrationSuccessDialogState();
}

class _RegistrationSuccessDialogState
    extends State<RegistrationSuccessDialog> {
  bool _isDownloading = false;
  bool _showStudentPassword = false;
  bool _showParentPassword = false;
  bool _showSinglePassword = false;

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleDownloadPdf() async {
    setState(() => _isDownloading = true);
    try {
      if (widget.isStudentParent && widget.student != null && widget.parent != null) {
        await PdfGeneratorService().downloadStudentParentSlip(
          student: widget.student!,
          studentPassword: widget.studentPassword ?? '',
          parent: widget.parent!,
          parentPassword: widget.parentPassword ?? '',
        );
      } else if (widget.singleUser != null) {
        await PdfGeneratorService().downloadSingleUserSlip(
          user: widget.singleUser!,
          password: widget.singlePassword ?? '',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('PDF Slip downloaded successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download PDF: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Widget _buildCredentialRow({
    required IconData icon,
    required String label,
    required String value,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    bool allowCopy = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              isPassword && obscure ? '••••••••' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isPassword ? const Color(0xFF1E40AF) : const Color(0xFF1E293B),
                fontFamily: isPassword ? 'monospace' : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isPassword)
            IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 16,
                color: const Color(0xFF64748B),
              ),
              onPressed: onToggleObscure,
              tooltip: obscure ? 'Show' : 'Hide',
              visualDensity: VisualDensity.compact,
            ),
          if (allowCopy)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF2563EB)),
              onPressed: () => _copyToClipboard(value, label),
              tooltip: 'Copy',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildMergedStudentParentContent() {
    final s = widget.student!;
    final p = widget.parent!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Admission highlight badge
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.badge_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GENERATED ADMISSION NUMBER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.admissionNo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Color(0xFF2563EB), size: 18),
                onPressed: () => _copyToClipboard(s.admissionNo, 'Admission No'),
                tooltip: 'Copy Admission No',
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Student Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.school_rounded, color: Color(0xFF2563EB), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Student: ${s.name}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s.gradeOrClass,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
              const Divider(height: 18),
              _buildCredentialRow(
                icon: Icons.alternate_email_rounded,
                label: 'Login Email',
                value: s.email,
              ),
              _buildCredentialRow(
                icon: Icons.key_rounded,
                label: 'Password',
                value: widget.studentPassword ?? '',
                isPassword: true,
                obscure: !_showStudentPassword,
                onToggleObscure: () => setState(() => _showStudentPassword = !_showStudentPassword),
              ),
              _buildCredentialRow(
                icon: Icons.phone_iphone_rounded,
                label: 'Mobile',
                value: s.phone,
                allowCopy: false,
              ),
              _buildCredentialRow(
                icon: Icons.phone_rounded,
                label: 'Home Phone',
                value: s.homePhone,
                allowCopy: false,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Parent Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.family_restroom_rounded, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Parent: ${p.name}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.gradeOrClass, // Relationship
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF047857)),
                    ),
                  ),
                ],
              ),
              const Divider(height: 18),
              _buildCredentialRow(
                icon: Icons.alternate_email_rounded,
                label: 'Login Email',
                value: p.email,
              ),
              _buildCredentialRow(
                icon: Icons.key_rounded,
                label: 'Password',
                value: widget.parentPassword ?? '',
                isPassword: true,
                obscure: !_showParentPassword,
                onToggleObscure: () => setState(() => _showParentPassword = !_showParentPassword),
              ),
              _buildCredentialRow(
                icon: Icons.phone_iphone_rounded,
                label: 'Mobile',
                value: p.phone,
                allowCopy: false,
              ),
              if (p.nic.isNotEmpty)
                _buildCredentialRow(
                  icon: Icons.badge_outlined,
                  label: 'NIC / ID',
                  value: p.nic,
                  allowCopy: false,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSingleUserContent() {
    final u = widget.singleUser!;
    final isTeacher = u.role.toLowerCase() == 'teacher';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isTeacher ? const Color(0xFFEFF6FF) : const Color(0xFFDCEBFE),
                child: Text(
                  u.initials,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isTeacher ? const Color(0xFF1D4ED8) : const Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      isTeacher
                          ? 'Teacher ${u.gradeOrClass.isNotEmpty ? "• Class: ${u.gradeOrClass}" : ""}'
                          : '${u.role} ${u.gradeOrClass.isNotEmpty ? "• ${u.gradeOrClass}" : ""}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              if (u.admissionNo.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    u.admissionNo,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 22),
          if (isTeacher && u.admissionNo.isNotEmpty)
            _buildCredentialRow(
              icon: Icons.badge_outlined,
              label: 'Teacher ID',
              value: u.admissionNo,
            ),
          if (!isTeacher && u.admissionNo.isNotEmpty)
            _buildCredentialRow(
              icon: Icons.badge_outlined,
              label: u.role.toLowerCase() == 'admin' ? 'Admin ID' : 'Staff ID',
              value: u.admissionNo,
            ),
          _buildCredentialRow(
            icon: Icons.alternate_email_rounded,
            label: 'Login Email',
            value: u.email,
          ),
          _buildCredentialRow(
            icon: Icons.key_rounded,
            label: 'Password',
            value: widget.singlePassword ?? '',
            isPassword: true,
            obscure: !_showSinglePassword,
            onToggleObscure: () => setState(() => _showSinglePassword = !_showSinglePassword),
          ),
          if (!isTeacher && u.gradeOrClass.isNotEmpty)
            _buildCredentialRow(
              icon: Icons.apartment_rounded,
              label: 'Department',
              value: u.gradeOrClass,
              allowCopy: false,
            ),
          if (isTeacher && u.gradeOrClass.isNotEmpty)
            _buildCredentialRow(
              icon: Icons.meeting_room_outlined,
              label: 'Class Teacher',
              value: u.gradeOrClass,
              allowCopy: false,
            ),
          if (isTeacher && u.subjects.isNotEmpty)
            _buildCredentialRow(
              icon: Icons.menu_book_rounded,
              label: 'Subjects',
              value: u.subjectsFormatted,
              allowCopy: false,
            ),
          if (isTeacher && u.qualification.isNotEmpty)
            _buildCredentialRow(
              icon: Icons.school_outlined,
              label: 'Qualification',
              value: u.qualification,
              allowCopy: false,
            ),
          if (u.nic.isNotEmpty)
            _buildCredentialRow(
              icon: Icons.credit_card_rounded,
              label: 'NIC',
              value: u.nic,
              allowCopy: false,
            ),
          _buildCredentialRow(
            icon: Icons.phone_rounded,
            label: 'Phone',
            value: u.phone,
            allowCopy: false,
          ),
          if (u.homePhone.isNotEmpty)
            _buildCredentialRow(
              icon: Icons.phone_in_talk_rounded,
              label: 'Home Phone',
              value: u.homePhone,
              allowCopy: false,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success Header Icon
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 36,
                ),
              ),
              const SizedBox(height: 14),

              Text(
                widget.isStudentParent
                    ? 'Student & Parent Registered!'
                    : '${widget.singleUser?.role ?? "User"} Registered Successfully!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Account credentials have been generated. You can copy the credentials or download the official PDF slip below.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 18),

              if (widget.isStudentParent)
                _buildMergedStudentParentContent()
              else
                _buildSingleUserContent(),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF334155),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _handleDownloadPdf,
                      icon: _isDownloading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.picture_as_pdf_rounded, size: 20),
                      label: Text(
                        _isDownloading ? 'Downloading...' : 'Download PDF Slip',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
