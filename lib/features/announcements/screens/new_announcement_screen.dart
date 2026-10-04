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
  final _audienceController = TextEditingController(text: 'All / Parents / Teachers / Students');
  final _categoryController = TextEditingController(text: 'General');
  final _messageController = TextEditingController();

  bool _sendNotification = true;
  bool _isPublishing = false;

  @override
  void dispose() {
    _titleController.dispose();
    _audienceController.dispose();
    _categoryController.dispose();
    _messageController.dispose();
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

  Future<void> _handlePublish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isPublishing = true);

    final item = AnnouncementItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      category: _categoryController.text.trim().isEmpty ? 'General' : _categoryController.text.trim(),
      timeAgo: 'Just now',
      audience: _audienceController.text.trim(),
      message: _messageController.text.trim(),
      sendNotification: _sendNotification,
      createdAt: DateTime.now(),
    );

    await AnnouncementService().addAnnouncement(item);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Announcement "${item.title}" published to database!'),
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
                      _buildTextField(
                        controller: _audienceController,
                        hintText: 'All / Parents / Teachers / Students',
                      ),

                      const SizedBox(height: 18),

                      _buildFieldLabel('Category'),
                      _buildTextField(
                        controller: _categoryController,
                        hintText: 'General',
                      ),

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
                  child: const Text(
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
