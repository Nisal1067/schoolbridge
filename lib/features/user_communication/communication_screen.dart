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
  late Future<List<Map<String, dynamic>>> _contacts = _service.contacts();
  bool _opening = false;

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
    backgroundColor: const Color(0xFFF6F7F9),
    appBar: AppBar(
      title: const Text('Messages'),
      actions: [
        IconButton(
          tooltip: 'Refresh contacts',
          onPressed: () => setState(() => _contacts = _service.contacts()),
          icon: const Icon(Icons.refresh),
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
            const Text(
              'Conversations',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
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
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final chats = snapshot.data!.docs.toList()
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
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.chat_bubble_outline),
                      ),
                      title: Text(title),
                      subtitle: Text(
                        data['lastMessage'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChatScreen(chatId: doc.id, title: title),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const Divider(height: 32),
            const Text(
              'Contacts',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            if (people.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No linked contacts. Ask your admin to check student parent links and teacher class assignments.',
                ),
              ),
            for (final contact in people)
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(contact['label']),
                trailing: const Icon(Icons.chevron_right),
                enabled: !_opening,
                onTap: () => _open(contact),
              ),
            if (_opening) const LinearProgressIndicator(),
          ],
        );
      },
    ),
  );
}
