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
  final _studentFormKey = GlobalKey<FormState>();
  final _parentFormKey = GlobalKey<FormState>();
  final _singleFormKey = GlobalKey<FormState>();

  // Only Student, Teacher, and Admin can be selected directly.
  // Parents are registered immediately along with their student!
  final List<String> _roles = ['Student', 'Teacher', 'Admin'];
  String _selectedRole = 'Student';
  int _currentStep = 0; // 0: Student details, 1: Parent details

  // Student / General fields
  final _nameController = TextEditingController();
  final _admissionNoController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _homePhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  final _gradeController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedGender = 'Male';
  bool _obscurePassword = true;

  // Parent fields (Step 2)
  final _parentNameController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentNicController = TextEditingController();
  final _parentOccupationController = TextEditingController();
  final _parentPasswordController = TextEditingController();
  String _parentRelationship = 'Father';
  bool _obscureParentPassword = true;

  bool _isSubmitting = false;

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _relationships = ['Father', 'Mother', 'Guardian', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _admissionNoController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _homePhoneController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _gradeController.dispose();
    _passwordController.dispose();

    _parentNameController.dispose();
    _parentEmailController.dispose();
    _parentPhoneController.dispose();
    _parentNicController.dispose();
    _parentOccupationController.dispose();
    _parentPasswordController.dispose();
    super.dispose();
  }

  String _currentJoinedDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 14)),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Widget _buildFieldLabel(String label, {bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          if (isOptional)
            const Text(
              ' (Optional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF94A3B8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    Widget? prefixIcon,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
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
        obscureText: isPassword && obscure,
        validator: validator,
        maxLines: maxLines,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          filled: false,
          prefixIcon: prefixIcon,
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
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  onPressed: onToggleObscure,
                )
              : suffixIcon,
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Step 1
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _currentStep == 0
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF10B981),
                  child: Icon(
                    _currentStep > 0 ? Icons.check : Icons.school_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Step 1',
                        style: TextStyle(
                          fontSize: 11,
                          color: _currentStep == 0
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'Student Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider arrow
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
          ),

          // Step 2
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _currentStep == 1
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
                  child: Icon(
                    Icons.family_restroom_rounded,
                    size: 15,
                    color: _currentStep == 1 ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Step 2',
                        style: TextStyle(
                          fontSize: 11,
                          color: _currentStep == 1
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Parent Registration',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _currentStep == 1
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Select Role'),
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
                      _currentStep = 0;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFDCEBFE)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
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
                        fontSize: 13,
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
      ],
    );
  }

  // Handle single user creation (Teacher or Admin)
  Future<void> _handleCreateSingleUser() async {
    if (!_singleFormKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final newUser = UserItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? '077 000 0000'
          : _phoneController.text.trim(),
      address: _addressController.text.trim(),
      homePhone: _homePhoneController.text.trim(),
      role: _selectedRole,
      gradeOrClass: _gradeController.text.trim().isEmpty
          ? (_selectedRole == 'Teacher' ? '' : 'Administration')
          : _gradeController.text.trim(),
      status: 'Active',
      joinedDate: _currentJoinedDate(),
      parentIds: const [],
    );

    final password = _passwordController.text.trim().isNotEmpty
        ? _passwordController.text.trim()
        : '123456';

    try {
      await UserManagementService().addUser(newUser, password: password);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newUser.role} "${newUser.name}" registered successfully!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  // Handle student and parent linked creation
  Future<void> _handleRegisterStudentAndParent() async {
    if (!_parentFormKey.currentState!.validate()) return;

    final studentEmail = _emailController.text.trim().toLowerCase();
    final parentEmail = _parentEmailController.text.trim().toLowerCase();

    if (studentEmail == parentEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parent email cannot be identical to student email.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final joined = _currentJoinedDate();

    final student = UserItem(
      id: '',
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? '077 000 0000'
          : _phoneController.text.trim(),
      homePhone: _homePhoneController.text.trim(),
      address: _addressController.text.trim(),
      dob: _dobController.text.trim(),
      gender: _selectedGender,
      admissionNo: _admissionNoController.text.trim(),
      role: 'Student',
      gradeOrClass: _gradeController.text.trim().isEmpty
          ? '10-A'
          : _gradeController.text.trim(),
      status: 'Active',
      joinedDate: joined,
      parentIds: const [],
    );

    final parent = UserItem(
      id: '',
      name: _parentNameController.text.trim(),
      email: _parentEmailController.text.trim(),
      phone: _parentPhoneController.text.trim().isEmpty
          ? '077 000 0000'
          : _parentPhoneController.text.trim(),
      homePhone: _homePhoneController.text.trim(),
      address: _addressController.text.trim(),
      nic: _parentNicController.text.trim(),
      occupation: _parentOccupationController.text.trim(),
      role: 'Parent',
      gradeOrClass: _parentRelationship,
      status: 'Active',
      joinedDate: joined,
      parentIds: const [],
    );

    final studentPassword = _passwordController.text.trim().isNotEmpty
        ? _passwordController.text.trim()
        : '123456';
    final parentPassword = _parentPasswordController.text.trim().isNotEmpty
        ? _parentPasswordController.text.trim()
        : '123456';

    try {
      final result = await UserManagementService().addStudentWithParent(
        student: student,
        studentPassword: studentPassword,
        parent: parent,
        parentPassword: parentPassword,
      );

      if (mounted) {
        final sName = result['student']?.name ?? 'Student';
        final pName = result['parent']?.name ?? 'Parent';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully registered Student "$sName" & Parent "$pName"!',
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _goToParentStep() {
    if (!_studentFormKey.currentState!.validate()) return;
    setState(() {
      _currentStep = 1;
    });
  }

  // Step 1: Student Information Form with Real-World Fields
  Widget _buildStudentForm() {
    return Form(
      key: _studentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoleSelector(),
          const SizedBox(height: 18),

          _buildStepIndicator(),

          // Full Name
          _buildFieldLabel('Student Full Name'),
          _buildTextField(
            controller: _nameController,
            hintText: 'e.g. Kasun Chamara Perera',
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF94A3B8), size: 20),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter student full name'
                : null,
          ),
          const SizedBox(height: 16),

          // Admission No & Class/Grade in a Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Admission / Index No', isOptional: true),
                    _buildTextField(
                      controller: _admissionNoController,
                      hintText: 'e.g. STU-2026-0042',
                      prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF94A3B8), size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Class / Grade'),
                    _buildTextField(
                      controller: _gradeController,
                      hintText: 'e.g. 10-A',
                      prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFF94A3B8), size: 20),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter class (e.g. 10-A)'
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Student Email
          _buildFieldLabel('Student Email (Sign-in Account)'),
          _buildTextField(
            controller: _emailController,
            hintText: 'e.g. kasun@school.lk',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF94A3B8), size: 20),
            validator: (v) => (v == null || !v.contains('@'))
                ? 'Please enter a valid student email'
                : null,
          ),
          const SizedBox(height: 16),

          // Date of Birth & Gender in a Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Date of Birth', isOptional: true),
                    _buildTextField(
                      controller: _dobController,
                      hintText: 'YYYY-MM-DD',
                      readOnly: true,
                      onTap: () => _selectDateOfBirth(context),
                      prefixIcon: const Icon(Icons.calendar_month_outlined, color: Color(0xFF94A3B8), size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Gender', isOptional: true),
                    Container(
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
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        isExpanded: true,
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
                        items: _genders.map((g) {
                          return DropdownMenuItem(
                            value: g,
                            child: Text(g),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedGender = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Home Address (Optional)
          _buildFieldLabel('Home Address', isOptional: true),
          _buildTextField(
            controller: _addressController,
            hintText: 'e.g. No. 45, Temple Road, Colombo',
            prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8), size: 20),
          ),
          const SizedBox(height: 16),

          // Home Phone (Landline) & Student Mobile Phone
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Home Phone', isOptional: true),
                    _buildTextField(
                      controller: _homePhoneController,
                      hintText: 'e.g. 011 234 5678',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF94A3B8), size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Student Mobile', isOptional: true),
                    _buildTextField(
                      controller: _phoneController,
                      hintText: 'e.g. 077 123 4567',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_iphone_outlined, color: Color(0xFF94A3B8), size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Temporary Password for Student
          _buildFieldLabel('Temporary Password for Student'),
          _buildTextField(
            controller: _passwordController,
            hintText: 'Minimum 6 characters (Default: 123456)',
            isPassword: true,
            obscure: _obscurePassword,
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF94A3B8), size: 20),
            onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (v) => (v != null && v.isNotEmpty && v.length < 6)
                ? 'Password must be at least 6 characters'
                : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Step 2: Parent Information Form
  Widget _buildParentForm() {
    final studentName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Student';
    final studentGrade = _gradeController.text.trim().isNotEmpty
        ? _gradeController.text.trim()
        : 'Class';

    return Form(
      key: _parentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepIndicator(),

          // Linking Banner
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.link_rounded,
                  color: Color(0xFF2563EB),
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registering Parent For:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$studentName (Grade $studentGrade)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        _emailController.text.trim(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: const Text('Edit Student', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),

          // Parent Full Name
          _buildFieldLabel('Parent / Guardian Full Name'),
          _buildTextField(
            controller: _parentNameController,
            hintText: 'e.g. Nimal Perera',
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF94A3B8), size: 20),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter parent full name'
                : null,
          ),
          const SizedBox(height: 16),

          // Relationship & NIC in a Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Relationship'),
                    Container(
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
                      child: DropdownButtonFormField<String>(
                        initialValue: _parentRelationship,
                        isExpanded: true,
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
                        items: _relationships.map((rel) {
                          return DropdownMenuItem(
                            value: rel,
                            child: Text(rel),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _parentRelationship = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Parent NIC / ID', isOptional: true),
                    _buildTextField(
                      controller: _parentNicController,
                      hintText: 'e.g. 198012345678',
                      prefixIcon: const Icon(Icons.credit_card_outlined, color: Color(0xFF94A3B8), size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Parent Email
          _buildFieldLabel('Parent Email (Sign-in Account)'),
          _buildTextField(
            controller: _parentEmailController,
            hintText: 'e.g. nimal.perera@gmail.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF94A3B8), size: 20),
            validator: (v) => (v == null || !v.contains('@'))
                ? 'Please enter a valid parent email'
                : null,
          ),
          const SizedBox(height: 16),

          // Parent Primary Mobile Phone & Occupation
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Primary Mobile Phone'),
                    _buildTextField(
                      controller: _parentPhoneController,
                      hintText: 'e.g. 077 987 6543',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF94A3B8), size: 20),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter phone number'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Occupation', isOptional: true),
                    _buildTextField(
                      controller: _parentOccupationController,
                      hintText: 'e.g. Accountant',
                      prefixIcon: const Icon(Icons.work_outline, color: Color(0xFF94A3B8), size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Temporary Password for Parent
          _buildFieldLabel('Temporary Password for Parent'),
          _buildTextField(
            controller: _parentPasswordController,
            hintText: 'Minimum 6 characters (Default: 123456)',
            isPassword: true,
            obscure: _obscureParentPassword,
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF94A3B8), size: 20),
            onToggleObscure: () => setState(() => _obscureParentPassword = !_obscureParentPassword),
            validator: (v) => (v != null && v.isNotEmpty && v.length < 6)
                ? 'Password must be at least 6 characters'
                : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Standard form for other roles (Teacher or Admin)
  Widget _buildStandardForm() {
    return Form(
      key: _singleFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoleSelector(),
          const SizedBox(height: 20),

          _buildFieldLabel('Full Name'),
          _buildTextField(
            controller: _nameController,
            hintText: 'Enter full name',
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF94A3B8), size: 20),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter full name'
                : null,
          ),
          const SizedBox(height: 18),

          _buildFieldLabel('Email'),
          _buildTextField(
            controller: _emailController,
            hintText: 'Enter email address',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF94A3B8), size: 20),
            validator: (v) => (v == null || !v.contains('@'))
                ? 'Please enter a valid email'
                : null,
          ),
          const SizedBox(height: 18),

          _buildFieldLabel('Phone'),
          _buildTextField(
            controller: _phoneController,
            hintText: 'Enter phone number',
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF94A3B8), size: 20),
          ),
          const SizedBox(height: 18),

          _buildFieldLabel('Home Address', isOptional: true),
          _buildTextField(
            controller: _addressController,
            hintText: 'Enter address',
            prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8), size: 20),
          ),
          const SizedBox(height: 18),

          _buildFieldLabel(
            _selectedRole == 'Teacher'
                ? 'Class Teacher Of (e.g. 10-A)'
                : 'Role / Department',
          ),
          _buildTextField(
            controller: _gradeController,
            hintText: _selectedRole == 'Teacher'
                ? 'Enter class name (Leave empty if none)'
                : 'Enter role / department',
            prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFF94A3B8), size: 20),
          ),
          const SizedBox(height: 18),

          _buildFieldLabel('Temporary Password'),
          _buildTextField(
            controller: _passwordController,
            hintText: 'Enter password (Default: 123456)',
            isPassword: true,
            obscure: _obscurePassword,
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF94A3B8), size: 20),
            onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (v) => (v != null && v.isNotEmpty && v.length < 6)
                ? 'Password must be at least 6 characters'
                : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_selectedRole == 'Student') {
      if (_currentStep == 0) {
        // Continue to Parent Registration
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _goToParentStep,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
            label: const Text(
              'Continue to Parent Registration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        );
      } else {
        // Step 1: Submit both Student and Parent
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: _isSubmitting
                    ? null
                    : () => setState(() => _currentStep = 0),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E293B),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleRegisterStudentAndParent,
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
                        'Register Student & Parent',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ],
        );
      }
    }

    // Teacher or Admin
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _handleCreateSingleUser,
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
            : Text(
                'Create $_selectedRole',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String appBarTitle = _selectedRole == 'Student'
        ? (_currentStep == 0
            ? 'Add Student (Step 1/2)'
            : 'Parent Registration (Step 2/2)')
        : 'Add $_selectedRole';

    return PopScope(
      canPop: !(_selectedRole == 'Student' && _currentStep == 1),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_selectedRole == 'Student' && _currentStep == 1) {
          setState(() => _currentStep = 0);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        appBar: SchoolBridgeAppBar(
          title: appBarTitle,
          showBackButton: true,
          onLeadingPressed: () {
            if (_selectedRole == 'Student' && _currentStep == 1) {
              setState(() => _currentStep = 0);
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _selectedRole == 'Student'
                      ? (_currentStep == 0 ? _buildStudentForm() : _buildParentForm())
                      : _buildStandardForm(),
                ),
              ),

              // Bottom Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: _buildBottomBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
