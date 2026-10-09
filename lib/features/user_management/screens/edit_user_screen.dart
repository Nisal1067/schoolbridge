import 'package:flutter/material.dart';

import '../models/user_item.dart';
import '../services/user_management_service.dart';
import '../widgets/custom_app_bar.dart';

class EditUserScreen extends StatefulWidget {
  final UserItem user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _homePhoneController;
  late TextEditingController _addressController;
  late TextEditingController _roleController;
  late TextEditingController _classController;
  late TextEditingController _statusController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _emailController = TextEditingController(text: widget.user.email);
    _phoneController = TextEditingController(text: widget.user.phone);
    _homePhoneController = TextEditingController(text: widget.user.homePhone);
    _addressController = TextEditingController(text: widget.user.address);
    _roleController = TextEditingController(text: widget.user.role);
    _classController = TextEditingController(text: widget.user.gradeOrClass);
    _statusController = TextEditingController(text: widget.user.status);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _homePhoneController.dispose();
    _addressController.dispose();
    _roleController.dispose();
    _classController.dispose();
    _statusController.dispose();
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
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
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
        validator: validator,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
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
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updated = widget.user.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      homePhone: _homePhoneController.text.trim(),
      address: _addressController.text.trim(),
      role: _roleController.text.trim(),
      gradeOrClass: _classController.text.trim(),
      status: _statusController.text.trim().isEmpty
          ? 'Active'
          : _statusController.text.trim(),
      parentIds: widget.user.parentIds,
    );

    try {
      await UserManagementService().updateUser(updated);
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not update user. Please try again.',
            ),
          ),
        );
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User "${updated.name}" updated successfully!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      Navigator.of(context).pop(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: const SchoolBridgeAppBar(
        title: 'Edit User',
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
                      _buildFieldLabel('Full Name'),
                      _buildTextField(
                        controller: _nameController,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter full name'
                            : null,
                      ),

                      const SizedBox(height: 18),

                      _buildFieldLabel('Email'),
                      _buildTextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@'))
                            ? 'Please enter a valid email'
                            : null,
                      ),

                      const SizedBox(height: 18),

                      _buildFieldLabel('Phone'),
                      _buildTextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 18),

                      _buildFieldLabel('Home Phone / Landline (Optional)'),
                      _buildTextField(
                        controller: _homePhoneController,
                        keyboardType: TextInputType.phone,
                        hintText: 'e.g. 011 234 5678',
                      ),

                      const SizedBox(height: 18),

                      _buildFieldLabel('Home Address (Optional)'),
                      _buildTextField(
                        controller: _addressController,
                        hintText: 'e.g. No. 45, Temple Road, Colombo',
                      ),

                      const SizedBox(height: 18),

                      _buildFieldLabel('Role'),
                      _buildTextField(controller: _roleController),

                      const SizedBox(height: 18),

                      _buildFieldLabel('Class / Department'),
                      _buildTextField(controller: _classController),

                      const SizedBox(height: 18),

                      _buildFieldLabel('Status (Active / Inactive)'),
                      _buildTextField(controller: _statusController),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
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
