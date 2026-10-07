import 'package:flutter/material.dart';
import '../models/user_item.dart';
import '../services/user_management_service.dart';
import '../widgets/custom_app_bar.dart';
import 'edit_user_screen.dart';

class UserDetailsScreen extends StatefulWidget {
  final UserItem user;

  const UserDetailsScreen({super.key, required this.user});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  late UserItem _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    UserManagementService().usersStream.listen((users) {
      final updated = users.where((u) => u.id == _currentUser.id).toList();
      if (updated.isNotEmpty && mounted) {
        setState(() {
          _currentUser = updated.first;
        });
      }
    });
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
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
                // Soft blue icon box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEBFE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    color: const Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),

                // Label and Value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

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
    final isActive = _currentUser.status.toLowerCase() == 'active';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: const SchoolBridgeAppBar(
        title: 'User Details',
        showBackButton: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // User Avatar with Initials
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCEBFE),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _currentUser.initials,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // User Full Name
                    Text(
                      _currentUser.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // User Role / Subtitle
                    Text(
                      _currentUser.subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Status Badge (Active / Inactive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _currentUser.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Detail items
                    _buildDetailCard(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: _currentUser.email,
                    ),
                    _buildDetailCard(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: _currentUser.phone,
                    ),
                    _buildDetailCard(
                      icon: Icons.badge_outlined,
                      label: 'Role',
                      value: _currentUser.role,
                    ),
                    _buildDetailCard(
                      icon: Icons.school_outlined,
                      label: 'Class',
                      value: _currentUser.gradeOrClass.isNotEmpty
                          ? _currentUser.gradeOrClass
                          : 'Not assigned',
                    ),
                    if (_currentUser.admissionNo.isNotEmpty)
                      _buildDetailCard(
                        icon: Icons.confirmation_number_outlined,
                        label: 'Admission / Index No',
                        value: _currentUser.admissionNo,
                      ),
                    if (_currentUser.dob.isNotEmpty)
                      _buildDetailCard(
                        icon: Icons.cake_outlined,
                        label: 'Date of Birth',
                        value: _currentUser.dob,
                      ),
                    if (_currentUser.gender.isNotEmpty)
                      _buildDetailCard(
                        icon: Icons.person_outline,
                        label: 'Gender',
                        value: _currentUser.gender,
                      ),
                    if (_currentUser.address.isNotEmpty)
                      _buildDetailCard(
                        icon: Icons.location_on_outlined,
                        label: 'Home Address',
                        value: _currentUser.address,
                      ),
                    if (_currentUser.homePhone.isNotEmpty)
                      _buildDetailCard(
                        icon: Icons.contact_phone_outlined,
                        label: 'Home Phone / Landline',
                        value: _currentUser.homePhone,
                      ),
                    if (_currentUser.nic.isNotEmpty)
                      _buildDetailCard(
                        icon: Icons.credit_card_outlined,
                        label: 'NIC / National ID',
                        value: _currentUser.nic,
                      ),
                    if (_currentUser.occupation.isNotEmpty)
                      _buildDetailCard(
                        icon: Icons.work_outline,
                        label: 'Occupation',
                        value: _currentUser.occupation,
                      ),
                    _buildDetailCard(
                      icon: Icons.calendar_today_outlined,
                      label: 'Joined',
                      value: _currentUser.joinedDate,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Edit User Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.of(context).push<UserItem>(
                      MaterialPageRoute(
                        builder: (_) => EditUserScreen(user: _currentUser),
                      ),
                    );
                    if (result != null && mounted) {
                      setState(() {
                        _currentUser = result;
                      });
                    }
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
                    'Edit User',
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
