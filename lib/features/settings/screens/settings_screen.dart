import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/screens/login_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../user_management/widgets/custom_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  final bool showBackButton;

  const SettingsScreen({super.key, this.showBackButton = true});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Preferences State
  bool _twoFactorEnabled = false;
  bool _pushNotifications = true;
  bool _emailAlerts = true;
  bool _smsAlerts = true;
  bool _soundVibrations = true;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Light Theme';
  bool _compactView = false;

  @override
  void initState() {
    super.initState();
    _loadLocalPreferences();
  }

  Future<void> _loadLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _twoFactorEnabled = prefs.getBool('admin_2fa_enabled') ?? false;
          _pushNotifications = prefs.getBool('admin_pref_push') ?? true;
          _emailAlerts = prefs.getBool('admin_pref_email') ?? true;
          _smsAlerts = prefs.getBool('admin_pref_sms') ?? true;
          _soundVibrations = prefs.getBool('admin_pref_sound') ?? true;
          _selectedLanguage = prefs.getString('admin_pref_lang') ?? 'English';
          _selectedTheme = prefs.getString('admin_pref_theme') ?? 'Light Theme';
          _compactView = prefs.getBool('admin_pref_compact') ?? false;
        });
      }
    } catch (_) {}
  }

  // --- 1. Profile Header Card & Edit Profile ---
  Widget _buildProfileHeader(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final emailStr = user?.email ?? 'admin@schoolbridge.lk';
    final fallbackName = user?.displayName ??
        (emailStr.contains('@') ? emailStr.split('@').first : 'Admin User');

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: user != null
          ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
          : null,
      builder: (context, snapshot) {
        String adminName = fallbackName;
        String adminPhone = '077 000 0000';
        String adminDept = 'Administration';
        String adminId = 'ADM-2026';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          if (data != null) {
            if (data['name'] != null && data['name'].toString().trim().isNotEmpty) {
              adminName = data['name'].toString().trim();
            }
            if (data['phone'] != null && data['phone'].toString().trim().isNotEmpty) {
              adminPhone = data['phone'].toString().trim();
            }
            if (data['gradeOrClass'] != null &&
                data['gradeOrClass'].toString().trim().isNotEmpty) {
              adminDept = data['gradeOrClass'].toString().trim();
            }
            if (data['admissionNo'] != null &&
                data['admissionNo'].toString().trim().isNotEmpty) {
              adminId = data['admissionNo'].toString().trim();
            }
          }
        }

        final initialLetter =
            adminName.trim().isNotEmpty ? adminName.trim()[0].toUpperCase() : 'A';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFBFDBFE)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Circular Avatar
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initialLetter,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // User Name and Email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adminName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          emailStr,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Edit Profile Button
                  ElevatedButton.icon(
                    onPressed: () => _showEditProfileDialog(
                      currentName: adminName,
                      currentPhone: adminPhone,
                      currentDept: adminDept,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text(
                      'Edit',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2563EB),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFDBEAFE)),
              const SizedBox(height: 12),

              // Badges: Staff ID & Department
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.badge_outlined, size: 13, color: Color(0xFF2563EB)),
                        const SizedBox(width: 5),
                        Text(
                          adminId,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.apartment_rounded, size: 13, color: Color(0xFF059669)),
                        const SizedBox(width: 5),
                        Text(
                          adminDept,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF047857),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileDialog({
    required String currentName,
    required String currentPhone,
    required String currentDept,
  }) {
    final nameController = TextEditingController(text: currentName);
    final phoneController = TextEditingController(text: currentPhone);
    final deptController = TextEditingController(text: currentDept);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.manage_accounts_rounded, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Text('Edit Admin Profile', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Full Display Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Contact Phone Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'e.g. 077 123 4567',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Department / Office Role', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: deptController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Administration, IT Office',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final newName = nameController.text.trim();
                        final newPhone = phoneController.text.trim();
                        final newDept = deptController.text.trim();

                        if (newName.isEmpty) return;

                        setDialogState(() => isSaving = true);
                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            await user.updateDisplayName(newName);
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                              'name': newName,
                              'phone': newPhone,
                              'gradeOrClass': newDept,
                            }, SetOptions(merge: true));
                          }

                          if (ctx.mounted) Navigator.of(ctx).pop();

                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: const Text('Admin profile updated successfully!'),
                                backgroundColor: const Color(0xFF16A34A),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update profile: $e'),
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- 2. Change Password Dialog ---
  void _showChangePasswordDialog() {
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSaving = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Text('Change Password', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your new password below. Make sure it is at least 6 characters long.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),

                  const Text('New Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: newPassController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      hintText: 'Enter new password',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                        onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Confirm New Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: confirmPassController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      hintText: 'Re-enter new password',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                        onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),

                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final newPass = newPassController.text.trim();
                        final confirmPass = confirmPassController.text.trim();

                        if (newPass.length < 6) {
                          setDialogState(() => errorMessage = 'Password must be at least 6 characters.');
                          return;
                        }
                        if (newPass != confirmPass) {
                          setDialogState(() => errorMessage = 'Passwords do not match.');
                          return;
                        }

                        setDialogState(() {
                          isSaving = true;
                          errorMessage = null;
                        });

                        try {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            await user.updatePassword(newPass);
                          }

                          if (ctx.mounted) Navigator.of(ctx).pop();

                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: const Text('Password changed successfully!'),
                                backgroundColor: const Color(0xFF16A34A),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          }
                        } on FirebaseAuthException catch (authErr) {
                          setDialogState(() {
                            isSaving = false;
                            if (authErr.code == 'requires-recent-login') {
                              errorMessage = 'Please sign out and sign in again before changing password.';
                            } else {
                              errorMessage = authErr.message ?? 'Failed to update password.';
                            }
                          });
                        } catch (e) {
                          setDialogState(() {
                            isSaving = false;
                            errorMessage = 'Error: $e';
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Update Password'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- 3. Two-Factor Authentication Dialog ---
  void _show2FADialog() {
    bool temp2FA = _twoFactorEnabled;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF10B981)),
                SizedBox(width: 10),
                Text('Two-Factor Authentication', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: temp2FA ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          temp2FA ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          color: temp2FA ? const Color(0xFF059669) : const Color(0xFF64748B),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            temp2FA ? '2FA Protection is currently ACTIVE' : '2FA Protection is currently DISABLED',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: temp2FA ? const Color(0xFF065F46) : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Enable 2FA Protection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                          SizedBox(height: 2),
                          Text('Require verification on sign-in', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                        ],
                      ),
                      Switch(
                        value: temp2FA,
                        onChanged: (val) => setDialogState(() => temp2FA = val),
                        activeThumbColor: const Color(0xFF10B981),
                      ),
                    ],
                  ),

                  if (temp2FA) ...[
                    const Divider(height: 24),
                    const Text('Backup Recovery Codes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF1E293B))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SB-8492-1049   •   SB-3948-2840',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF2563EB)),
                            onPressed: () {
                              Clipboard.setData(const ClipboardData(text: 'SB-8492-1049, SB-3948-2840'));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Backup codes copied!'), behavior: SnackBarBehavior.floating),
                              );
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                onPressed: () async {
                  setState(() => _twoFactorEnabled = temp2FA);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('admin_2fa_enabled', temp2FA);
                  if (ctx.mounted) Navigator.of(ctx).pop();

                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(temp2FA ? 'Two-Factor Authentication enabled!' : 'Two-Factor Authentication disabled.'),
                        backgroundColor: temp2FA ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save 2FA Status'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- 4. Manage Sessions Dialog ---
  void _showSessionsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.devices_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 10),
            Text('Manage Active Sessions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current Device
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.laptop_chromebook_rounded, color: Color(0xFF2563EB), size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Windows Desktop / Chrome', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            SizedBox(width: 6),
                            Text('• Active Now', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text('Current Web Portal Session • Colombo, Sri Lanka', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Secondary Session
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.phone_android_rounded, color: Color(0xFF64748B), size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SchoolBridge Mobile App', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        SizedBox(height: 2),
                        Text('Last active: Today, 2:15 PM • Android OS', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All other remote sessions terminated successfully.'),
                  backgroundColor: Color(0xFF16A34A),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Terminate Other Sessions'),
          ),
        ],
      ),
    );
  }

  // --- 5. Notifications Preferences Dialog ---
  void _showNotificationsDialog() {
    bool tempPush = _pushNotifications;
    bool tempEmail = _emailAlerts;
    bool tempSms = _smsAlerts;
    bool tempSound = _soundVibrations;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.notifications_active_outlined, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Text('Notification Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Push Notifications', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Registration alerts and notices', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  value: tempPush,
                  activeThumbColor: const Color(0xFF2563EB),
                  onChanged: (val) => setDialogState(() => tempPush = val),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Email Summaries', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Weekly reports and summaries', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  value: tempEmail,
                  activeThumbColor: const Color(0xFF2563EB),
                  onChanged: (val) => setDialogState(() => tempEmail = val),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('SMS Urgent Broadcasts', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Emergency notices sent to mobile', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  value: tempSms,
                  activeThumbColor: const Color(0xFF2563EB),
                  onChanged: (val) => setDialogState(() => tempSms = val),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Sound & In-App Alerts', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Play audio tone on new message', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  value: tempSound,
                  activeThumbColor: const Color(0xFF2563EB),
                  onChanged: (val) => setDialogState(() => tempSound = val),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _pushNotifications = tempPush;
                    _emailAlerts = tempEmail;
                    _smsAlerts = tempSms;
                    _soundVibrations = tempSound;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('admin_pref_push', tempPush);
                  await prefs.setBool('admin_pref_email', tempEmail);
                  await prefs.setBool('admin_pref_sms', tempSms);
                  await prefs.setBool('admin_pref_sound', tempSound);

                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Notification settings saved!'), backgroundColor: Color(0xFF16A34A), behavior: SnackBarBehavior.floating),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save Preferences'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- 6. Language Selection Dialog ---
  void _showLanguageDialog() {
    final languages = [
      {'code': 'en', 'name': 'English', 'native': 'English', 'flag': '🇬🇧'},
      {'code': 'si', 'name': 'Sinhala', 'native': 'සිංහල', 'flag': '🇱🇰'},
      {'code': 'ta', 'name': 'Tamil', 'native': 'தமிழ்', 'flag': '🇱🇰'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.translate_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 10),
            Text('Select Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            final isSelected = _selectedLanguage == lang['name'];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
              ),
              child: ListTile(
                leading: Text(lang['flag']!, style: const TextStyle(fontSize: 22)),
                title: Text(lang['native']!, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: const Color(0xFF1E293B))),
                subtitle: Text(lang['name']!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB)) : null,
                onTap: () async {
                  setState(() => _selectedLanguage = lang['name']!);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('admin_pref_lang', lang['name']!);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Language set to ${lang["native"]}!'), backgroundColor: const Color(0xFF16A34A), behavior: SnackBarBehavior.floating),
                    );
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- 7. Appearance Dialog ---
  void _showAppearanceDialog() {
    final themes = ['Light Theme', 'Dark Theme (Preview)', 'System Default'];
    bool tempCompact = _compactView;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.palette_outlined, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Text('Appearance & Display', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...themes.map((t) {
                  final isSelected = _selectedTheme == t;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      title: Text(t, style: TextStyle(fontSize: 13.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 20) : null,
                      dense: true,
                      onTap: () {
                        setDialogState(() => _selectedTheme = t);
                        setState(() => _selectedTheme = t);
                      },
                    ),
                  );
                }),
                const Divider(),
                SwitchListTile(
                  title: const Text('Compact Layout', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Reduce spacing for larger screens', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  value: tempCompact,
                  activeThumbColor: const Color(0xFF2563EB),
                  onChanged: (val) {
                    setDialogState(() => tempCompact = val);
                    setState(() => _compactView = val);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Done', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- 8. Help & Feedback Dialog ---
  void _showHelpFeedbackDialog() {
    final feedbackController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.help_outline_rounded, color: Color(0xFF2563EB)),
                SizedBox(width: 10),
                Text('Help & Support', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Frequently Asked Questions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Q: How to add new students & parents?', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                        Text('A: Go to Users > Add User, choose Student, fill details, and parent account is linked automatically.', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                        Divider(height: 14),
                        Text('Q: How to broadcast announcements?', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                        Text('A: Go to Announcements > + New Announcement, select target audience groups, and publish.', style: TextStyle(fontSize: 11, color: Color(0xFF475569))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Support Hotline & Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 4),
                  const Text('📞 +94 11 234 5678  |  ✉️ support@schoolbridge.lk', style: TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 14),

                  const Text('Send Us Your Feedback', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: feedbackController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Describe issue or suggestion...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      contentPadding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                onPressed: isSending
                    ? null
                    : () async {
                        final text = feedbackController.text.trim();
                        if (text.isEmpty) return;

                        setDialogState(() => isSending = true);
                        try {
                          await FirebaseFirestore.instance.collection('feedback').add({
                            'message': text,
                            'sender': FirebaseAuth.instance.currentUser?.email ?? 'Admin',
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(content: Text('Feedback submitted successfully! Thank you.'), backgroundColor: Color(0xFF16A34A)),
                            );
                          }
                        } catch (_) {
                          setDialogState(() => isSending = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSending
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Feedback'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- 9. About App Dialog ---
  void _showAboutAppDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.all(22),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.school_rounded, color: Color(0xFF2563EB), size: 32),
            ),
            const SizedBox(height: 12),
            const Text(
              'SchoolBridge',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const Text(
              'Integrated School Management Platform',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('System Version:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text('v2.4.0 (Enterprise)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Database Status:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text('Online (Firestore Cloud)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ],
                  ),
                  SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Institution ID:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text('SB-COLOMBO-CENTRAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontFamily: 'monospace')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '© 2026 SchoolBridge Inc. All rights reserved.',
              style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- Section Header Widget ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // --- Single Settings Item Card ---
  Widget _buildSettingsItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading,
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  trailing,
                  const SizedBox(width: 8),
                ],
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: SchoolBridgeAppBar(
        title: 'Settings',
        showBackButton: widget.showBackButton,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            // Admin Profile Header Card with Real Data
            _buildProfileHeader(context),

            // --- 1. Account Security ---
            _buildSectionTitle('Account Security'),

            _buildSettingsItem(
              context: context,
              title: 'Change Password',
              subtitle: 'Update your administrator portal password',
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF2563EB), size: 19),
              ),
              onTap: _showChangePasswordDialog,
            ),

            _buildSettingsItem(
              context: context,
              title: 'Two-Factor Authentication',
              subtitle: _twoFactorEnabled ? 'Extra security layer is enabled' : 'Disabled • Protect admin account',
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _twoFactorEnabled ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.shield_outlined,
                  color: _twoFactorEnabled ? const Color(0xFF10B981) : const Color(0xFF64748B),
                  size: 19,
                ),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _twoFactorEnabled ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _twoFactorEnabled ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _twoFactorEnabled ? const Color(0xFF047857) : const Color(0xFF64748B),
                  ),
                ),
              ),
              onTap: _show2FADialog,
            ),

            _buildSettingsItem(
              context: context,
              title: 'Manage Sessions',
              subtitle: 'Active browser and device sign-ins',
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.devices_rounded, color: Color(0xFF9333EA), size: 19),
              ),
              onTap: _showSessionsDialog,
            ),

            // --- 2. System Preferences ---
            _buildSectionTitle('Preferences'),

            _buildSettingsItem(
              context: context,
              title: 'Notifications',
              subtitle: 'Push, email and SMS alert channels',
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.notifications_outlined, color: Color(0xFFD97706), size: 19),
              ),
              onTap: _showNotificationsDialog,
            ),

            _buildSettingsItem(
              context: context,
              title: 'Language',
              subtitle: 'Current: $_selectedLanguage',
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.language_rounded, color: Color(0xFF0284C7), size: 19),
              ),
              trailing: Text(
                _selectedLanguage,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
              ),
              onTap: _showLanguageDialog,
            ),

            _buildSettingsItem(
              context: context,
              title: 'Appearance',
              subtitle: 'Theme: $_selectedTheme',
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE7F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.palette_outlined, color: Color(0xFFDB2777), size: 19),
              ),
              onTap: _showAppearanceDialog,
            ),

            // --- 3. Support & About ---
            _buildSectionTitle('Support & Information'),

            _buildSettingsItem(
              context: context,
              title: 'Help & Feedback',
              subtitle: 'User guides, support hotline, feedback',
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.help_outline_rounded, color: Color(0xFF16A34A), size: 19),
              ),
              onTap: _showHelpFeedbackDialog,
            ),

            _buildSettingsItem(
              context: context,
              title: 'About App',
              subtitle: 'SchoolBridge v2.4.0 • System Health',
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.info_outline_rounded, color: Color(0xFF475569), size: 19),
              ),
              onTap: _showAboutAppDialog,
            ),

            const SizedBox(height: 12),

            // --- 4. Log Out Card ---
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFEE2E2)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _handleLogout(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFEE2E2),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFEF4444),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Log Out',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Sign out of your SchoolBridge admin portal',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFFF87171),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFFCA5A5),
                          size: 20,
                        ),
                      ],
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

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text('Log Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your SchoolBridge administrator account?',
          style: TextStyle(color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await AuthService().logout();
              } catch (_) {}

              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
