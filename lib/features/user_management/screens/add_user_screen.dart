import 'package:flutter/material.dart';

import '../models/user_item.dart';
import '../services/user_management_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/registration_success_dialog.dart';

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

  // Student class & section state (Select Grade + Type Section)
  String _studentSelectedGrade = 'Grade 10';
  final _studentSectionController = TextEditingController(text: 'A');

  // Teacher class & section state (Select Grade + Type Section)
  String _teacherSelectedGrade = 'None';
  final _teacherSectionController = TextEditingController();

  // Scroll controller for subjects
  final ScrollController _subjectScrollController = ScrollController();

  final List<String> _schoolGrades = [
    'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5',
    'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10',
    'Grade 11', 'Grade 12', 'Grade 13',
  ];

  final List<String> _teacherGradeOptions = [
    'None',
    'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5',
    'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10',
    'Grade 11', 'Grade 12', 'Grade 13',
  ];

  final List<String> _quickSections = ['A', 'B', 'C', 'D', 'E'];
  final List<String> _advancedSections = ['A', 'B', 'C', 'Bio', 'Maths', 'Commerce', 'Arts', 'Tech'];

  // Teacher-specific controllers & state
  final _teacherNicController = TextEditingController();
  final _teacherQualificationController = TextEditingController();
  final _teacherCustomSubjectController = TextEditingController();

  // Admin-specific controllers
  final _adminNicController = TextEditingController();
  final List<String> _selectedSubjects = [];
  final List<String> _commonSubjects = [
    'Mathematics',
    'Science',
    'English Language',
    'English Literature',
    'Sinhala Language & Lit.',
    'Tamil Language & Lit.',
    'History',
    'ICT',
    'Commerce',
    'Accounting',
    'Economics',
    'Business Studies',
    'Buddhism',
    'Christianity',
    'Catholicism',
    'Hinduism',
    'Islam',
    'Art',
    'Western Music',
    'Eastern Music',
    'Dancing',
    'Drama & Theatre',
    'Geography',
    'Civic Education',
    'Health & Physical Education',
    'Agriculture',
    'Home Science',
    'Design & Technology',
    'Combined Mathematics',
    'Biology',
    'Physics',
    'Chemistry',
    'Political Science',
    'Logic & Scientific Method',
    'Media Studies',
    'French',
    'Japanese',
    'German',
    'Chinese',
  ];

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

  void _syncStudentClass() {
    final sec = _studentSectionController.text.trim().toUpperCase();
    _gradeController.text = sec.isNotEmpty ? '$_studentSelectedGrade-$sec' : _studentSelectedGrade;
  }

  void _syncTeacherClass() {
    if (_teacherSelectedGrade == 'None' || _teacherSelectedGrade == 'None (Subject Teacher Only)') {
      _gradeController.text = '';
    } else {
      final sec = _teacherSectionController.text.trim().toUpperCase();
      _gradeController.text = sec.isNotEmpty ? '$_teacherSelectedGrade-$sec' : _teacherSelectedGrade;
    }
  }

  void _addCustomSubject() {
    final text = _teacherCustomSubjectController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        if (!_commonSubjects.contains(text)) {
          _commonSubjects.insert(0, text);
        }
        if (!_selectedSubjects.contains(text)) {
          _selectedSubjects.add(text);
        }
        _teacherCustomSubjectController.clear();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _passwordController.text = UserManagementService.generateSecurePassword();
    _parentPasswordController.text = UserManagementService.generateSecurePassword();
    _syncStudentClass();
  }

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

    _studentSectionController.dispose();
    _teacherSectionController.dispose();
    _subjectScrollController.dispose();

    _teacherNicController.dispose();
    _teacherQualificationController.dispose();
    _teacherCustomSubjectController.dispose();
    _adminNicController.dispose();

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

  Future<void> _selectTeacherDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 30)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
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

  Widget _buildAutoPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required VoidCallback onRegenerate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.vpn_key_rounded,
                  color: Color(0xFF2563EB),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Temporary Password',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'AUTO-GENERATED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      obscure ? '••••••••' : controller.text,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        fontFamily: 'monospace',
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF94A3B8),
                  size: 20,
                ),
                onPressed: onToggleObscure,
                tooltip: obscure ? 'Show' : 'Hide',
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB), size: 20),
                onPressed: onRegenerate,
                tooltip: 'Generate New Password',
              ),
            ],
          ),
        ),
      ],
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
                      if (role == 'Admin' && _gradeController.text.isEmpty) {
                        _gradeController.text = 'Administration';
                      }
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

    final isTeacher = _selectedRole == 'Teacher';
    final isAdmin = _selectedRole == 'Admin';

    if (isTeacher) {
      _syncTeacherClass();
    }

    if (isTeacher && _selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or add at least one subject for the teacher.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final password = _passwordController.text.trim().isNotEmpty
        ? _passwordController.text.trim()
        : UserManagementService.generateSecurePassword();

    final rawAssignedClass = _gradeController.text.trim();
    final cleanAssignedClass = (rawAssignedClass == 'None' ||
            rawAssignedClass == 'None (Subject Teacher Only)')
        ? ''
        : rawAssignedClass;

    final newUser = UserItem(
      id: '',
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? '077 000 0000'
          : _phoneController.text.trim(),
      address: _addressController.text.trim(),
      homePhone: _homePhoneController.text.trim(),
      dob: _dobController.text.trim(),
      gender: _selectedGender,
      admissionNo: '', // Auto-assigned by system as TCH-YYYY-XXXX or ADM-YYYY-XXXX
      nic: isTeacher
          ? _teacherNicController.text.trim()
          : (isAdmin ? _adminNicController.text.trim() : ''),
      role: _selectedRole,
      gradeOrClass: isTeacher
          ? cleanAssignedClass
          : (_gradeController.text.trim().isEmpty
              ? 'Administration'
              : _gradeController.text.trim()),
      subjects: isTeacher ? List<String>.from(_selectedSubjects) : const [],
      qualification: isTeacher ? _teacherQualificationController.text.trim() : '',
      status: 'Active',
      joinedDate: _currentJoinedDate(),
      parentIds: const [],
    );

    try {
      final createdUser = await UserManagementService().addUser(
        newUser,
        password: password,
      );
      if (mounted) {
        setState(() => _isSubmitting = false);
        await RegistrationSuccessDialog.showSingleUser(
          context,
          user: createdUser,
          password: password,
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
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

  // Handle student and parent linked creation
  Future<void> _handleRegisterStudentAndParent() async {
    _syncStudentClass();
    if (!_parentFormKey.currentState!.validate()) return;

    final studentEmail = _emailController.text.trim().toLowerCase();
    final parentEmail = _parentEmailController.text.trim().toLowerCase();

    if (studentEmail.isNotEmpty && studentEmail == parentEmail) {
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
      phone: _phoneController.text.trim(),
      homePhone: _homePhoneController.text.trim(),
      address: _addressController.text.trim(),
      dob: _dobController.text.trim(),
      gender: _selectedGender,
      admissionNo: '', // Auto-generated unique admission number by system
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
      phone: _parentPhoneController.text.trim(),
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
        : UserManagementService.generateSecurePassword();
    final parentPassword = _parentPasswordController.text.trim().isNotEmpty
        ? _parentPasswordController.text.trim()
        : UserManagementService.generateSecurePassword();

    try {
      final result = await UserManagementService().addStudentWithParent(
        student: student,
        studentPassword: studentPassword,
        parent: parent,
        parentPassword: parentPassword,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        final finalStudent = result['student'] as UserItem;
        final finalParent = result['parent'] as UserItem;
        final sPass = (result['studentPassword'] as String?) ?? studentPassword;
        final pPass = (result['parentPassword'] as String?) ?? parentPassword;

        await RegistrationSuccessDialog.showStudentParent(
          context,
          student: finalStudent,
          studentPassword: sPass,
          parent: finalParent,
          parentPassword: pPass,
        );

        if (mounted) {
          Navigator.of(context).pop();
        }
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

          // Admission No (Auto-Generated)
          _buildFieldLabel('Admission / Index No'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Color(0xFF2563EB), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Auto-generated by system upon registration',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                Text(
                  'STU-YYYY-XXXX',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Class Assignment: Select Grade & Type Section (A, B...)
          _buildFieldLabel('Class / Grade (Select Grade & Type Section A, B...)'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x04000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grade Selector
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Grade',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _studentSelectedGrade,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2563EB)),
                                items: _schoolGrades.map((g) {
                                  return DropdownMenuItem(
                                    value: g,
                                    child: Text(
                                      g,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _studentSelectedGrade = val;
                                      _syncStudentClass();
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Section Type Input
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Type Section (A, B...)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: TextFormField(
                              controller: _studentSectionController,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'e.g. A, B',
                                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                isDense: true,
                              ),
                              onChanged: (_) {
                                setState(() {
                                  _syncStudentClass();
                                });
                              },
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Enter section'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Quick Section Chips & Live Preview
                Row(
                  children: [
                    const Text(
                      'Quick:',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _quickSections.map((sec) {
                            final isCur = _studentSectionController.text.trim().toUpperCase() == sec;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _studentSectionController.text = sec;
                                    _syncStudentClass();
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isCur ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCur ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    sec,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: isCur ? Colors.white : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.school_rounded, size: 14, color: Color(0xFF2563EB)),
                          const SizedBox(width: 6),
                          Text(
                            _gradeController.text.isNotEmpty ? _gradeController.text : '$_studentSelectedGrade-A',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Student Email (Optional)
          _buildFieldLabel('Student Email (Sign-in Account)', isOptional: true),
          _buildTextField(
            controller: _emailController,
            hintText: 'e.g. kasun@school.lk (Optional - auto-generated if blank)',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF94A3B8), size: 20),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              if (!v.contains('@') || !v.contains('.')) {
                return 'Please enter a valid email address';
              }
              return null;
            },
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

          // Home Phone (Landline) & Student Mobile Phone (Both Mandatory)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Home Phone (Landline)'),
                    _buildTextField(
                      controller: _homePhoneController,
                      hintText: 'e.g. 011 234 5678',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF94A3B8), size: 20),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter home phone'
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
                    _buildFieldLabel('Student Mobile'),
                    _buildTextField(
                      controller: _phoneController,
                      hintText: 'e.g. 077 123 4567',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_iphone_outlined, color: Color(0xFF94A3B8), size: 20),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter student mobile'
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // System Auto-Generated Password for Student
          _buildAutoPasswordField(
            controller: _passwordController,
            label: 'Student Temporary Password',
            obscure: _obscurePassword,
            onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
            onRegenerate: () => setState(() {
              _passwordController.text = UserManagementService.generateSecurePassword();
            }),
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

          // System Auto-Generated Password for Parent
          _buildAutoPasswordField(
            controller: _parentPasswordController,
            label: 'Parent Temporary Password',
            obscure: _obscureParentPassword,
            onToggleObscure: () => setState(() => _obscureParentPassword = !_obscureParentPassword),
            onRegenerate: () => setState(() {
              _parentPasswordController.text = UserManagementService.generateSecurePassword();
            }),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  // Dedicated real-world Teacher Registration Form
  Widget _buildTeacherForm() {
    return Form(
      key: _singleFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoleSelector(),
          const SizedBox(height: 18),

          // Header Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Faculty & Teacher Registration',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Assign class teacher responsibility, teaching subjects, and generate official appointment slip with credentials.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF3B82F6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- 1. Teacher Identification ---
          _buildSectionHeader(
            icon: Icons.badge_outlined,
            title: '1. Teacher Identity & Personal Profile',
          ),
          const SizedBox(height: 12),

          // Full Name
          _buildFieldLabel('Teacher Full Name'),
          _buildTextField(
            controller: _nameController,
            hintText: 'e.g. K.A. Sunimal Fernando',
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF94A3B8), size: 20),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter teacher full name' : null,
          ),
          const SizedBox(height: 14),

          // Teacher ID Badge (Auto Generated)
          _buildFieldLabel('Teacher / Employee ID'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Generated: TCH-${DateTime.now().year}-XXXX',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Text(
                        'Unique sequence will be assigned by system upon registration',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'AUTO',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // NIC
          _buildFieldLabel('National Identity Card (NIC)'),
          _buildTextField(
            controller: _teacherNicController,
            hintText: 'e.g. 198512345678 or 851234567V',
            prefixIcon: const Icon(Icons.credit_card_outlined, color: Color(0xFF94A3B8), size: 20),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter NIC number' : null,
          ),
          const SizedBox(height: 14),

          // Gender & Date of Birth
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Gender'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGender,
                          isExpanded: true,
                          items: _genders.map((g) {
                            return DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13.5)));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedGender = val);
                          },
                        ),
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
                    _buildFieldLabel('Date of Birth', isOptional: true),
                    _buildTextField(
                      controller: _dobController,
                      hintText: 'YYYY-MM-DD',
                      readOnly: true,
                      onTap: () => _selectTeacherDateOfBirth(context),
                      prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF94A3B8), size: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // --- 2. Academic Responsibilities & Subjects ---
          _buildSectionHeader(
            icon: Icons.menu_book_rounded,
            title: '2. Academic Responsibilities & Subjects',
          ),
          const SizedBox(height: 12),

          // Class Teacher Of (Select Grade & Type Section A, B...)
          _buildFieldLabel('Class Teacher Of (Select Grade & Type Section A, B...)', isOptional: true),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x04000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grade Selector Dropdown
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Select Grade',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _teacherSelectedGrade,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2563EB)),
                                items: _teacherGradeOptions.map((g) {
                                  final label = g == 'None' ? 'None (Subject Teacher)' : g;
                                  return DropdownMenuItem(
                                    value: g,
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: g == 'None' ? FontWeight.normal : FontWeight.w600,
                                        color: g == 'None' ? const Color(0xFF64748B) : const Color(0xFF1E293B),
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _teacherSelectedGrade = val;
                                      if (val != 'None' && _teacherSectionController.text.isEmpty) {
                                        _teacherSectionController.text = 'A';
                                      }
                                      _syncTeacherClass();
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Section Type Input
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Type Section (A, B...)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: _teacherSelectedGrade == 'None'
                                  ? const Color(0xFFF1F5F9)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: TextFormField(
                              controller: _teacherSectionController,
                              enabled: _teacherSelectedGrade != 'None',
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                              decoration: InputDecoration(
                                hintText: _teacherSelectedGrade == 'None' ? 'N/A' : 'e.g. A, B',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                isDense: true,
                              ),
                              onChanged: (_) {
                                setState(() {
                                  _syncTeacherClass();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_teacherSelectedGrade != 'None') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        'Quick:',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _advancedSections.map((sec) {
                              final isCur = _teacherSectionController.text.trim().toUpperCase() == sec;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _teacherSectionController.text = sec;
                                      _syncTeacherClass();
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isCur ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isCur ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Text(
                                      sec,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: isCur ? Colors.white : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                // Live preview badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _teacherSelectedGrade == 'None'
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _teacherSelectedGrade == 'None'
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _teacherSelectedGrade == 'None'
                            ? Icons.info_outline_rounded
                            : Icons.check_circle_rounded,
                        size: 14,
                        color: _teacherSelectedGrade == 'None'
                            ? const Color(0xFF64748B)
                            : const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _teacherSelectedGrade == 'None'
                            ? 'Role: Subject Teacher (No classroom assigned)'
                            : 'Class Teacher of: ${_gradeController.text}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _teacherSelectedGrade == 'None'
                              ? const Color(0xFF64748B)
                              : const Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Teaching Subjects Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFieldLabel('Teaching Subjects (Scroll to Select)'),
              if (_selectedSubjects.isNotEmpty)
                Text(
                  '${_selectedSubjects.length} selected',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
            ],
          ),

          // Scrollable Container for Subjects
          Container(
            height: 185,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x04000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Scrollbar(
              controller: _subjectScrollController,
              thumbVisibility: true,
              radius: const Radius.circular(8),
              thickness: 5,
              child: SingleChildScrollView(
                controller: _subjectScrollController,
                padding: const EdgeInsets.only(right: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _commonSubjects.map((subject) {
                    final isSelected = _selectedSubjects.contains(subject);
                    return FilterChip(
                      selected: isSelected,
                      label: Text(subject),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF334155),
                      ),
                      selectedColor: const Color(0xFFDBEAFE),
                      backgroundColor: const Color(0xFFF8FAFC),
                      checkmarkColor: const Color(0xFF1D4ED8),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedSubjects.add(subject);
                          } else {
                            _selectedSubjects.remove(subject);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Type other / additional subject input (මීට අමතර විෂයක් නම් මෙහි type කරන්න)
          _buildFieldLabel('Type Other / Additional Subject (මීට අමතර විෂයක් නම්)', isOptional: true),
          Row(
            children: [
              Expanded(
                child: Container(
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
                    controller: _teacherCustomSubjectController,
                    decoration: const InputDecoration(
                      hintText: 'Type any other subject name (e.g. Robotics, French)',
                      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      prefixIcon: Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB), size: 22),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    onFieldSubmitted: (_) => _addCustomSubject(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _addCustomSubject,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),

          // Selected Subjects Display
          if (_selectedSubjects.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Assigned Subjects (${_selectedSubjects.length}):',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _selectedSubjects.clear()),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 20),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Clear All', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _selectedSubjects.map((s) {
                      return Chip(
                        label: Text(s, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
                        backgroundColor: const Color(0xFFEFF6FF),
                        side: const BorderSide(color: Color(0xFFBFDBFE)),
                        deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF2563EB)),
                        onDeleted: () => setState(() => _selectedSubjects.remove(s)),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Educational Qualifications
          _buildFieldLabel('Educational Qualifications / Designation', isOptional: true),
          _buildTextField(
            controller: _teacherQualificationController,
            hintText: 'e.g. B.Sc. in Mathematics, NDT, Dip. in Education',
            prefixIcon: const Icon(Icons.school_outlined, color: Color(0xFF94A3B8), size: 20),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              'B.Sc. Degree',
              'B.Ed. Degree',
              'NDT (Teaching Dip.)',
              'PGDE',
              'M.Ed. Degree',
            ].map((q) {
              return ActionChip(
                label: Text(q, style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                backgroundColor: const Color(0xFFF1F5F9),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                onPressed: () {
                  setState(() {
                    if (_teacherQualificationController.text.isEmpty) {
                      _teacherQualificationController.text = q;
                    } else if (!_teacherQualificationController.text.contains(q)) {
                      _teacherQualificationController.text += ', $q';
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 22),

          // --- 3. Contact Information ---
          _buildSectionHeader(
            icon: Icons.contact_phone_outlined,
            title: '3. Contact Information & Sign-in Email',
          ),
          const SizedBox(height: 12),

          // Sign-in Email
          _buildFieldLabel('Teacher Sign-in Email (Portal Account)'),
          _buildTextField(
            controller: _emailController,
            hintText: 'e.g. sunimal.fernando@schoolbridge.lk',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF94A3B8), size: 20),
            validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid email address' : null,
          ),
          const SizedBox(height: 14),

          // Mobile & Home Phone
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Primary Mobile Phone'),
                    _buildTextField(
                      controller: _phoneController,
                      hintText: 'e.g. 077 123 4567',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF94A3B8), size: 20),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter mobile phone' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Home Phone', isOptional: true),
                    _buildTextField(
                      controller: _homePhoneController,
                      hintText: 'e.g. 011 234 5678',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_in_talk_outlined, color: Color(0xFF94A3B8), size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Address
          _buildFieldLabel('Residential Address', isOptional: true),
          _buildTextField(
            controller: _addressController,
            hintText: 'e.g. No. 45, Temple Road, Colombo',
            prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8), size: 20),
          ),
          const SizedBox(height: 22),

          // --- 4. Credentials & Password ---
          _buildSectionHeader(
            icon: Icons.vpn_key_outlined,
            title: '4. System Credentials & Auto-Generated Password',
          ),
          const SizedBox(height: 12),

          _buildAutoPasswordField(
            controller: _passwordController,
            label: 'Temporary Sign-in Password',
            obscure: _obscurePassword,
            onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
            onRegenerate: () => setState(() {
              _passwordController.text = UserManagementService.generateSecurePassword();
            }),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.print_outlined, color: Color(0xFF16A34A), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'An official Teacher Appointment & Credential Slip PDF containing the generated password and sign-in details will be ready to download upon registration.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Dedicated, streamlined Admin Registration Form
  Widget _buildAdminForm() {
    final currentYear = DateTime.now().year;

    return Form(
      key: _singleFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoleSelector(),
          const SizedBox(height: 18),

          // Header Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Administrator & Staff Registration',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Register administrative personnel with auto-generated Staff ID and system access credentials slip.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF3B82F6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- 1. Administrator Profile ---
          _buildSectionHeader(
            icon: Icons.badge_outlined,
            title: '1. Administrator Profile & Department',
          ),
          const SizedBox(height: 12),

          // Full Name
          _buildFieldLabel('Administrator Full Name'),
          _buildTextField(
            controller: _nameController,
            hintText: 'e.g. Dr. Mahinda Rajapaksha / A.B. Perera',
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF94A3B8), size: 20),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter administrator full name' : null,
          ),
          const SizedBox(height: 14),

          // Staff ID Badge (Auto Generated ADM-YYYY-XXXX)
          _buildFieldLabel('Staff / Administrator ID'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Generated: ADM-$currentYear-XXXX',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Text(
                        'Unique sequence will be assigned by system upon registration',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'AUTO',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // National ID (NIC)
          _buildFieldLabel('National Identity Card (NIC)', isOptional: true),
          _buildTextField(
            controller: _adminNicController,
            hintText: 'e.g. 197812345678 / 781234567V',
            prefixIcon: const Icon(Icons.credit_card_outlined, color: Color(0xFF94A3B8), size: 20),
          ),
          const SizedBox(height: 14),

          // Role / Department
          _buildFieldLabel('Department / Administrative Role'),
          _buildTextField(
            controller: _gradeController,
            hintText: 'e.g. Administration, Principal, IT Office',
            prefixIcon: const Icon(Icons.apartment_rounded, color: Color(0xFF94A3B8), size: 20),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              'Administration',
              'Principal',
              'Vice Principal',
              'IT Office',
              'Finance & Bursar',
              'Exam Branch',
              'Student Affairs',
            ].map((dept) {
              return ActionChip(
                label: Text(dept, style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155))),
                backgroundColor: const Color(0xFFF1F5F9),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                onPressed: () {
                  setState(() {
                    _gradeController.text = dept;
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 22),

          // --- 2. Contact Information ---
          _buildSectionHeader(
            icon: Icons.contact_phone_outlined,
            title: '2. Contact Information & Sign-in Email',
          ),
          const SizedBox(height: 12),

          // Sign-in Email
          _buildFieldLabel('Admin Sign-in Email (Portal Account)'),
          _buildTextField(
            controller: _emailController,
            hintText: 'e.g. admin@schoolbridge.lk',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF94A3B8), size: 20),
            validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid email address' : null,
          ),
          const SizedBox(height: 14),

          // Phone Numbers
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Primary Mobile Phone'),
                    _buildTextField(
                      controller: _phoneController,
                      hintText: 'e.g. 077 123 4567',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF94A3B8), size: 20),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter mobile phone' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Office / Landline Phone', isOptional: true),
                    _buildTextField(
                      controller: _homePhoneController,
                      hintText: 'e.g. 011 234 5678',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_in_talk_outlined, color: Color(0xFF94A3B8), size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Address
          _buildFieldLabel('Office / Residential Address', isOptional: true),
          _buildTextField(
            controller: _addressController,
            hintText: 'e.g. Administrative Block, School Premises',
            prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8), size: 20),
          ),
          const SizedBox(height: 22),

          // --- 3. System Access Credentials ---
          _buildSectionHeader(
            icon: Icons.vpn_key_outlined,
            title: '3. System Credentials & Auto-Generated Password',
          ),
          const SizedBox(height: 12),

          _buildAutoPasswordField(
            controller: _passwordController,
            label: 'Temporary Sign-in Password',
            obscure: _obscurePassword,
            onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
            onRegenerate: () => setState(() {
              _passwordController.text = UserManagementService.generateSecurePassword();
            }),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.print_outlined, color: Color(0xFF16A34A), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'An official Administrator Credential Slip PDF containing the generated password and sign-in details will be ready to download upon registration.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.3),
                  ),
                ),
              ],
            ),
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
    final isTeacher = _selectedRole == 'Teacher';
    final isAdmin = _selectedRole == 'Admin';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _handleCreateSingleUser,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                isTeacher
                    ? Icons.assignment_turned_in_rounded
                    : (isAdmin
                        ? Icons.admin_panel_settings_rounded
                        : Icons.person_add_rounded),
                size: 20,
              ),
        label: Text(
          _isSubmitting
              ? 'Processing...'
              : (isTeacher
                  ? 'Register Teacher & Generate Slip'
                  : (isAdmin
                      ? 'Register Administrator & Generate Slip'
                      : 'Create $_selectedRole')),
          style: const TextStyle(
            fontSize: 15.5,
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
                      : (_selectedRole == 'Teacher'
                          ? _buildTeacherForm()
                          : _buildAdminForm()),
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
