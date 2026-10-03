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
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 45, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary, Color(0xFF6892EE)],
                ),
              ),
              child: const Column(
                children: [
                  CircleAvatar(
                    radius: 31,
                    backgroundColor: Color(0x33FFFFFF),
                    child: Icon(
                      Icons.school_rounded,
                      size: 35,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    'Welcome to',
                    style: TextStyle(color: Color(0xDDFFFFFF), fontSize: 18),
                  ),

                  SizedBox(height: 5),

                  Text(
                    'SchoolBridge',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 35,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  SizedBox(height: 6),

                  Text(
                    'Select your role to login',
                    style: TextStyle(color: Color(0xCCFFFFFF)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: UserRole.values
                            .map(
                              (role) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
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

                      const SizedBox(height: 25),

                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'Email Address',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: passwordController,
                        obscureText: hidePassword,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
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

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Forgot Password?'),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 53,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: isLoading ? null : login,
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
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
        return Icons.settings_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? Colors.white : AppColors.textGrey,
            ),

            const SizedBox(height: 6),

            Text(
              role.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? Colors.white : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
