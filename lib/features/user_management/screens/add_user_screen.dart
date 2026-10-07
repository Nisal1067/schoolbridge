import 'package:flutter/material.dart';
import '../models/user_item.dart';
import '../services/user_management_service.dart';
import '../widgets/custom_app_bar.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedRole = 'Student';
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gradeController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;

  final List<String> _roles = ['Student', 'Teacher', 'Parent', 'Admin'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _gradeController.dispose();
    _passwordController.dispose();
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
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
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword && _obscurePassword,
        validator: validator,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
          ),
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Future<void> _handleCreateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final joinedString = '${months[now.month - 1]} ${now.day}, ${now.year}';

    final newUser = UserItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? '077 000 0000'
          : _phoneController.text.trim(),
      role: _selectedRole,
      gradeOrClass: _gradeController.text.trim().isEmpty
          ? (_selectedRole == 'Student'
              ? '10-A'
              : (_selectedRole == 'Teacher'
                  ? ''
                  : (_selectedRole == 'Parent' ? 'Parent' : 'Administration')))
          : _gradeController.text.trim(),
      status: 'Active',
      joinedDate: joinedString,
    );

    final password = _passwordController.text.trim().isNotEmpty
        ? _passwordController.text.trim()
        : '123456';

    await UserManagementService().addUser(newUser, password: password);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User "${newUser.name}" created successfully!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: const SchoolBridgeAppBar(
        title: 'Add New User',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Select Role Title
                      _buildFieldLabel('Select Role'),

                      // Role Cards
                      Row(
                        children: _roles.map((role) {
                          final isSelected = _selectedRole == role;

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedRole = role;
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFDCEBFE)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFFE2E8F0),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x04000000),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    role,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 20),

                      // Full Name Field
                      _buildFieldLabel('Full Name'),
                      _buildTextField(
                        controller: _nameController,
                        hintText: 'Enter full name',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Please enter full name' : null,
                      ),

                      const SizedBox(height: 18),

                      // Email Field
                      _buildFieldLabel('Email'),
                      _buildTextField(
                        controller: _emailController,
                        hintText: 'Enter email address',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || !v.contains('@')) ? 'Please enter a valid email' : null,
                      ),

                      const SizedBox(height: 18),

                      // Phone Field
                      _buildFieldLabel('Phone'),
                      _buildTextField(
                        controller: _phoneController,
                        hintText: 'Enter phone number',
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 18),

                      // Role / Grade Field
                      _buildFieldLabel(
                        _selectedRole == 'Teacher' 
                            ? 'Class Teacher Of (e.g. 10-A)' 
                            : (_selectedRole == 'Student' 
                                ? 'Student Class (e.g. 10-A)' 
                                : 'Role / Department'),
                      ),
                      _buildTextField(
                        controller: _gradeController,
                        hintText: _selectedRole == 'Teacher' 
                            ? 'Enter class name (Leave empty if none)' 
                            : (_selectedRole == 'Student' ? 'Enter class name' : 'Enter role'),
                      ),

                      const SizedBox(height: 18),

                      // Temporary Password Field
                      _buildFieldLabel('Temporary Password'),
                      _buildTextField(
                        controller: _passwordController,
                        hintText: 'Enter password',
                        isPassword: true,
                        validator: (v) =>
                            (v != null && v.isNotEmpty && v.length < 6)
                                ? 'Password must be at least 6 characters'
                                : null,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Create User Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleCreateUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create User',
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
