import 'package:flutter/material.dart';
import '../../../auth/screens/login_screen.dart';
import '../models/user_item.dart';
import '../services/user_management_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/role_filter_bar.dart';
import '../widgets/user_card.dart';
import 'add_user_screen.dart';
import 'user_details_screen.dart';

class UsersListScreen extends StatefulWidget {
  final bool showBottomNav;
  final ValueChanged<int>? onNavigateTab;

  const UsersListScreen({
    super.key,
    this.showBottomNav = false,
    this.onNavigateTab,
  });

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final UserManagementService _service = UserManagementService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'All';
  String _searchQuery = '';
  List<UserItem> _users = [];

  @override
  void initState() {
    super.initState();
    _users = _service.currentUsers;
    _service.fetchUsers();
    _service.usersStream.listen((users) {
      if (mounted) {
        setState(() {
          _users = users;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserItem> get _filteredUsers {
    return _users.where((user) {
      // Role filter
      if (_selectedFilter == 'Students' && user.role.toLowerCase() != 'student') {
        return false;
      }
      if (_selectedFilter == 'Teachers' && user.role.toLowerCase() != 'teacher') {
        return false;
      }
      if (_selectedFilter == 'Staff' &&
          user.role.toLowerCase() != 'staff' &&
          user.role.toLowerCase() != 'admin') {
        return false;
      }

      // Search query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchName = user.name.toLowerCase().contains(query);
        final matchRole = user.role.toLowerCase().contains(query);
        final matchGrade = user.gradeOrClass.toLowerCase().contains(query);
        final matchEmail = user.email.toLowerCase().contains(query);
        return matchName || matchRole || matchGrade || matchEmail;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: const SchoolBridgeAppBar(title: 'Users'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  // Search Field
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x06000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val.trim();
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search students, teachers, staff...',
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Color(0xFF94A3B8),
                          size: 22,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Role Filter Pills
                  RoleFilterBar(
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (filter) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  // + Add User Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddUserScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        '+ Add User',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // User List
            Expanded(
              child: _service.isLoading && _users.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2563EB),
                      ),
                    )
                  : _service.errorMessage != null && _users.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 48,
                                  color: Color(0xFFEF4444),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Database Access Restricted',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Firestore permission error: ${_service.errorMessage}\n\nPlease publish the updated Firestore rules in Firebase Console or Sign In with your admin account.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const LoginScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('Sign In with Admin Account'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline_rounded,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No ${_selectedFilter == "All" ? "" : _selectedFilter} users found in database',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final user = filtered[index];
                        return UserCard(
                          user: user,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => UserDetailsScreen(user: user),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
