import 'package:flutter/material.dart';
import '../../user_management/widgets/custom_app_bar.dart';
import '../models/announcement_item.dart';
import '../services/announcement_service.dart';

class NewAnnouncementScreen extends StatefulWidget {
  const NewAnnouncementScreen({super.key});

  @override
  State<NewAnnouncementScreen> createState() => _NewAnnouncementScreenState();
}

class _NewAnnouncementScreenState extends State<NewAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _categoryController = TextEditingController(text: 'General');
  final _messageController = TextEditingController();

  // Audience Target State
  final Set<String> _selectedAudiences = {'All'};
  String _selectedGradeScope = 'All Grades (Whole School)';

  final List<Map<String, dynamic>> _audienceRoles = [
    {
      'id': 'All',
      'label': 'All (Entire School)',
      'icon': Icons.public_rounded,
    },
    {
      'id': 'Students',
      'label': 'Students',
      'icon': Icons.school_rounded,
    },
    {
      'id': 'Parents',
      'label': 'Parents',
      'icon': Icons.family_restroom_rounded,
    },
    {
      'id': 'Teachers',
      'label': 'Teachers',
      'icon': Icons.badge_outlined,
    },
    {
      'id': 'Staff',
      'label': 'Staff & Admin',
      'icon': Icons.admin_panel_settings_rounded,
    },
  ];

  final List<String> _gradeScopeOptions = [
    'All Grades (Whole School)',
    'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5',
    'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10',
    'Grade 11', 'Grade 12', 'Grade 13',
    'Primary Section (Grades 1-5)',
    'Junior Section (Grades 6-9)',
    'Senior Section (Grades 10-11)',
    'Advanced Level (Grades 12-13)',
  ];

  final List<String> _availableCategories = [
    'General',
    'Academic',
    'Events',
    'Notice',
    'Sports',
    'Emergency',
  ];

  bool _sendNotification = true;
  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _toggleAudience(String id) {
    setState(() {
      if (id == 'All') {
        _selectedAudiences.clear();
        _selectedAudiences.add('All');
      } else {
        _selectedAudiences.remove('All');
        if (_selectedAudiences.contains(id)) {
          _selectedAudiences.remove(id);
          if (_selectedAudiences.isEmpty) {
            _selectedAudiences.add('All');
          }
        } else {
          _selectedAudiences.add(id);
          // If all 4 individual roles are selected, collapse back to 'All'
          if (_selectedAudiences.contains('Students') &&
              _selectedAudiences.contains('Parents') &&
              _selectedAudiences.contains('Teachers') &&
              _selectedAudiences.contains('Staff')) {
            _selectedAudiences.clear();
            _selectedAudiences.add('All');
          }
        }
      }
    });
  }

  String get _computedAudienceString {
    String rolesStr;
    if (_selectedAudiences.contains('All') || _selectedAudiences.length >= 4) {
      rolesStr = 'All';
    } else {
      final ordered = ['Students', 'Parents', 'Teachers', 'Staff']
          .where((r) => _selectedAudiences.contains(r))
          .toList();
      rolesStr = ordered.join(', ');
    }

    if (_selectedGradeScope != 'All Grades (Whole School)') {
      return rolesStr == 'All'
          ? 'All ($_selectedGradeScope)'
          : '$rolesStr ($_selectedGradeScope)';
    }
    return rolesStr;
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
    int maxLines = 1,
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
        maxLines: maxLines,
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildAudienceSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
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
            children: [
              const Icon(Icons.groups_rounded, size: 20, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              const Text(
                'Target Audience Groups',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              if (!_selectedAudiences.contains('All'))
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedAudiences.clear();
                      _selectedAudiences.add('All');
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Reset to All', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Quick Audience Multi-Select Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _audienceRoles.map((role) {
              final id = role['id'] as String;
              final isSelected = _selectedAudiences.contains(id);
              final icon = role['icon'] as IconData;
              final label = role['label'] as String;

              return InkWell(
                onTap: () => _toggleAudience(id),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 18,
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? const Color(0xFF1E40AF) : const Color(0xFF334155),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF2563EB)),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Target Grade / Level (Optional)
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              const Text(
                'Specific Grade / Academic Level (Optional):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGradeScope,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2563EB)),
                items: _gradeScopeOptions.map((g) {
                  return DropdownMenuItem(
                    value: g,
                    child: Text(
                      g,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: g.startsWith('All') ? FontWeight.bold : FontWeight.normal,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedGradeScope = val);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Computed Audience Preview Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.campaign_rounded, color: Color(0xFF2563EB), size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Audience: ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                ),
                Expanded(
                  child: Text(
                    _computedAudienceString,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Category'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableCategories.map((cat) {
            final isSelected = _categoryController.text.trim().toLowerCase() == cat.toLowerCase();
            return ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _categoryController.text = cat);
                }
              },
              selectedColor: const Color(0xFF2563EB),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
              side: BorderSide(
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _handlePublish() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAudiences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one target audience group.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isPublishing = true);

    final finalAudience = _computedAudienceString;

    final item = AnnouncementItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      category: _categoryController.text.trim().isEmpty ? 'General' : _categoryController.text.trim(),
      timeAgo: 'Just now',
      audience: finalAudience,
      message: _messageController.text.trim(),
      sendNotification: _sendNotification,
      createdAt: DateTime.now(),
    );

    await AnnouncementService().addAnnouncement(item);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Announcement "${item.title}" published for $finalAudience!'),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.of(context).pop(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: const SchoolBridgeAppBar(
        title: 'New Announcement',
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
                      _buildFieldLabel('Title'),
                      _buildTextField(
                        controller: _titleController,
                        hintText: 'Enter announcement title',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
                      ),

                      const SizedBox(height: 18),

                      _buildFieldLabel('Audience'),
                      _buildAudienceSelector(),

                      const SizedBox(height: 18),

                      _buildCategorySelector(),

                      const SizedBox(height: 18),

                      _buildFieldLabel('Message'),
                      _buildTextField(
                        controller: _messageController,
                        hintText: 'Type your message here...',
                        maxLines: 6,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Please enter message content' : null,
                      ),

                      const SizedBox(height: 20),

                      // Send Notification Toggle Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Send Notification',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Notify all selected users',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _sendNotification,
                              onChanged: (val) {
                                setState(() {
                                  _sendNotification = val;
                                });
                              },
                              activeThumbColor: const Color(0xFF2563EB),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Publish Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPublishing ? null : _handlePublish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isPublishing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Publish',
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
