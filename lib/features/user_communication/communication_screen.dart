import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_service.dart';
import 'chat_screen.dart';

import '../../models/user_role.dart';

class UserCommunicationScreen extends StatelessWidget {
  final UserRole role;

  const UserCommunicationScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    if (role == UserRole.admin) {
      return const UserManagementScreen();
    }

    return const CommunicationScreen();
  }
}

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text('Nadeesha Silva'),
              subtitle: Text('Teacher'),
              trailing: Icon(Icons.more_vert),
            ),
          ),

          Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text('Kasun Silva'),
              subtitle: Text('Parent'),
              trailing: Icon(Icons.more_vert),
            ),
          ),
        ],
      ),
    );
  }
}

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});
  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  final _service = ChatService();
  late final _conversations = _service.conversations();
  late final _preferences = _service.conversationPreferences();
  late Future<List<Map<String, dynamic>>> _contacts = _service.contacts();
  bool _opening = false;
  final _deleting = <String>{};

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete chat?'),
        content: const Text(
          'Remove this conversation from your list only? The other person keeps their chat history. New messages will show it again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _deleting.contains(id)) return;
    setState(() => _deleting.add(id));
    try {
      await _service.deleteConversation(id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete chat. Please retry.')),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting.remove(id));
    }
  }

  Future<void> _open(Map<String, dynamic> contact) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final id = await _service.start(contact);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(chatId: id, title: contact['label']),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open chat. Check account links and permissions.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    appBar: AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Messages',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            tooltip: 'Refresh contacts',
            onPressed: () => setState(() => _contacts = _service.contacts()),
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4F46E5)),
          ),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _contacts,
      builder: (context, contacts) {
        if (contacts.hasError) {
          return const Center(
            child: Text(
              'Could not load contacts. Check your connection and linked accounts.',
            ),
          );
        }
        if (!contacts.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final people = contacts.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Text(
                'Conversations',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF1E293B)),
              ),
            ),
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _preferences,
              builder: (context, preferences) {
                if (preferences.hasError) {
                  return const Text(
                    'Could not load chat preferences. Please retry.',
                  );
                }
                if (!preferences.hasData) {
                  return const LinearProgressIndicator();
                }
                final deleted = preferences.data!.data()?['deletedChats'];
                final hidden = deleted is Map ? deleted : const {};
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _conversations,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Could not load conversations. Check permissions.',
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator();
                    }
                    final chats =
                        snapshot.data!.docs
                            .where(
                              (doc) => !ChatService.isConversationHidden(
                                hidden[doc.id],
                                doc.data()['lastMessageAt'],
                              ),
                            )
                            .toList()
                          ..sort(
                            (a, b) =>
                                ((b.data()['lastMessageAt'] as Timestamp?)
                                            ?.millisecondsSinceEpoch ??
                                        0)
                                    .compareTo(
                                      (a.data()['lastMessageAt'] as Timestamp?)
                                              ?.millisecondsSinceEpoch ??
                                          0,
                                    ),
                          );
                    if (chats.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No conversations yet.'),
                      );
                    }
                    return Column(
                      children: chats.map((doc) {
                        final data = doc.data();
                        final matches = people.where(
                          (p) =>
                              p['teacherId'] == data['teacherId'] &&
                              p['parentId'] == data['parentId'],
                        );
                        final title = matches.isEmpty
                            ? 'Parent-Teacher Chat'
                            : matches.first['label'] as String;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 22),
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF0F172A)),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                data['lastMessage'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                            ),
                            trailing: IconButton(
                              tooltip: 'Delete chat for me',
                              onPressed: _deleting.contains(doc.id)
                                  ? null
                                  : () => _delete(doc.id),
                              icon: _deleting.contains(doc.id)
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
                                      ),
                                    )
                                  : const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                            ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChatScreen(chatId: doc.id, title: title),
                            ),
                          ),
                        ),
                      );
                      }).toList(),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            const Divider(height: 32, color: Color(0xFFE2E8F0)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                'Contacts',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF1E293B)),
              ),
            ),
            if (people.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No linked contacts. Ask your admin to check student parent links and teacher class assignments.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
              ),
            for (final contact in people)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.person_outline_rounded, color: Color(0xFF64748B), size: 20),
                  ),
                  title: Text(contact['label'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF334155))),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                  enabled: !_opening,
                  onTap: () => _open(contact),
                ),
              ),
            if (_opening) const LinearProgressIndicator(),
          ],
        );
      },
    ),
  );
}
