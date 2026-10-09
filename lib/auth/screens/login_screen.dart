import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../dashboards/screens/admin_dashboard.dart';
import '../../dashboards/screens/parent_dashboard.dart';
import '../../dashboards/screens/student_dashboard.dart';
import '../../dashboards/screens/teacher_dashboard.dart';
import '../../models/user_role.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole selectedRole = UserRole.student;

  final emailController = TextEditingController();

  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;
  final authService = AuthService();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final role = await authService.login(
        emailController.text,
        passwordController.text,
        selectedRole: selectedRole,
      );
      if (!mounted) return;
      Widget dashboard;

      switch (role) {
        case UserRole.student:
          dashboard = const StudentDashboard();
          break;

        case UserRole.teacher:
          dashboard = const TeacherDashboard();
          break;

        case UserRole.parent:
          dashboard = const ParentDashboard();
          break;

        case UserRole.admin:
          dashboard = const AdminDashboard();
          break;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => dashboard),
        (_) => false,
      );
    } on RoleMismatchException catch (error) {
      if (!mounted) return;
      setState(() {
        selectedRole = error.actualRole;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: emailController.text.trim(),
    );
    bool isSubmitting = false;
    String? resetError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your registered email address and we will send you a secure password reset link.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selected role hint
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Color(0xFF475569),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Target Role: ${selectedRole.displayName}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text(
                    'Account Email',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'e.g. user@schoolbridge.lk',
                      prefixIcon: const Icon(Icons.mail_outline, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),

                  if (resetError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFEE2E2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFEF4444),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              resetError!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFEF4444),
                              ),
                            ),
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
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final email = resetEmailController.text.trim();
                        if (email.isEmpty) {
                          setDialogState(
                            () => resetError = 'Please enter an email address.',
                          );
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                          resetError = null;
                        });

                        try {
                          await authService.sendPasswordResetEmail(email);

                          if (ctx.mounted) Navigator.of(ctx).pop();

                          if (mounted) {
                            _showResetSuccessDialog(email);
                          }
                        } on AuthException catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            resetError = e.message;
                          });
                        } catch (e) {
                          setDialogState(() {
                            isSubmitting = false;
                            resetError = 'Failed to send reset email: $e';
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Send Reset Link',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetSuccessDialog(String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.mark_email_read_rounded,
                color: Color(0xFF16A34A),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reset Link Sent!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A password reset link has been dispatched to $email. Please check your inbox (and spam folder) to set a new password.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FAFF), Color(0xFFEAF1FF), Color(0xFFDCE9FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _LoginHero(),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white, width: 1.4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A)
                                .withValues(alpha: 0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            selectedRole == UserRole.admin
                                ? 'Admin sign in'
                                : 'Sign in',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontSize: 24),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            selectedRole == UserRole.admin
                                ? 'Securely access your school management workspace.'
                                : 'Choose your role and continue to your workspace.',
                            style: const TextStyle(
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: UserRole.values
                                .map(
                                  (role) => Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        right: role == UserRole.admin ? 0 : 8,
                                      ),
                                      child: _RoleButton(
                                        role: role,
                                        selected: selectedRole == role,
                                        onTap: () {
                                          setState(() {
                                            selectedRole = role;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              hintText: 'name@schoolbridge.lk',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: passwordController,
                            obscureText: hidePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    hidePassword = !hidePassword;
                                  });
                                },
                                icon: Icon(
                                  hidePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: isLoading ? null : login,
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(fontSize: 16),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.24),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            size: 38,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'SchoolBridge',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'A smarter school portal for every role.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textGrey,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RoleButton extends StatelessWidget {
  final UserRole role;
  final bool selected;
  final VoidCallback onTap;

  const _RoleButton({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  IconData get icon {
    switch (role) {
      case UserRole.parent:
        return Icons.group_outlined;

      case UserRole.teacher:
        return Icons.person_outline;

      case UserRole.student:
        return Icons.menu_book_outlined;

      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? (role == UserRole.admin
                    ? const Color(0xFFE0E7FF)
                    : const Color(0xFFDBEAFE))
              : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? (role == UserRole.admin
                      ? const Color(0xFF4F46E5)
                      : AppColors.primary)
                : const Color(0xFFE2E8F0),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x140F3DBD),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 21,
              color: selected
                  ? (role == UserRole.admin
                        ? const Color(0xFF3730A3)
                        : AppColors.primaryDark)
                  : AppColors.textGrey,
            ),

            const SizedBox(height: 6),

            Text(
              role.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? (role == UserRole.admin
                          ? const Color(0xFF3730A3)
                          : AppColors.primaryDark)
                    : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
