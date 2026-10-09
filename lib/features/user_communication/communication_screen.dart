import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'chat_service.dart';
import 'chat_screen.dart';

import '../../core/theme/app_theme.dart';
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
  final _search = TextEditingController();
  String _query = '';
  bool _opening = false;
  final _deleting = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

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
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: const Text('Messages'),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            tooltip: 'Refresh contacts',
            onPressed: () => setState(() => _contacts = _service.contacts()),
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E40AF)),
          ),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: _contacts,
      builder: (context, contacts) {
        if (contacts.hasError) {
          return Center(
            child: Text(
              'Could not load contacts. Error: ${contacts.error}\nCheck your connection and linked accounts.',
            ),
          );
        }
        if (!contacts.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final people = contacts.data!;
        final filteredPeople = _query.isEmpty
            ? people
            : people
                  .where(
                    (contact) => (contact['label'] as String)
                        .toLowerCase()
                        .contains(_query),
                  )
                  .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.primaryDark,
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SchoolBridge Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Parent-teacher conversations and linked contacts.',
                    style: TextStyle(
                      color: Color(0xD9FFFFFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _search,
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      hintText: 'Search conversations',
                      hintStyle: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.white70,
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                              ),
                            ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: const BorderSide(color: Colors.white54),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const _SectionTitle(
              title: 'Conversations',
              icon: Icons.chat_bubble_outline_rounded,
            ),
            const SizedBox(height: 10),
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
                      return const _EmptyPanel(
                        icon: Icons.forum_outlined,
                        title: 'No conversations yet',
                        subtitle: 'Open a contact below to start a chat.',
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
                        if (_query.isNotEmpty &&
                            !title.toLowerCase().contains(_query) &&
                            !(data['lastMessage'] as String? ?? '')
                                .toLowerCase()
                                .contains(_query)) {
                          return const SizedBox.shrink();
                        }
                        return _ConversationTile(
                          title: title,
                          subtitle: data['lastMessage'] as String? ?? '',
                          deleting: _deleting.contains(doc.id),
                          onDelete: () => _delete(doc.id),
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
                );
              },
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Contacts',
              icon: Icons.people_outline_rounded,
              count: filteredPeople.length,
            ),
            const SizedBox(height: 10),
            if (filteredPeople.isEmpty)
              const _EmptyPanel(
                icon: Icons.person_search_outlined,
                title: 'No contacts found',
                subtitle: 'Try a different name or ask your admin to check links.',
              ),
            for (final contact in filteredPeople)
              _ContactTile(
                title: contact['label'] as String,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final int? count;

  const _SectionTitle({required this.title, required this.icon, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool deleting;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationTile({
    required this.title,
    required this.subtitle,
    required this.deleting,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        leading: _Avatar(label: title, active: true),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 15.5,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Row(
            children: [
              const Icon(
                Icons.done_all_rounded,
                size: 15,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  subtitle.isEmpty ? 'No messages yet' : subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: IconButton(
          tooltip: 'Delete chat for me',
          onPressed: deleting ? null : onDelete,
          icon: deleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                ),
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final String title;
  final bool enabled;
  final VoidCallback onTap;

  const _ContactTile({
    required this.title,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        enabled: enabled,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        leading: _Avatar(label: title, active: false),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: const Text(
          'Tap to open chat',
          style: TextStyle(color: AppColors.textGrey, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF94A3B8),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String label;
  final bool active;

  const _Avatar({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final initial = label.trim().isEmpty ? '?' : label.trim()[0].toUpperCase();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [AppColors.secondary, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: active ? null : const Color(0xFFF8FAFC),
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? Colors.transparent : const Color(0xFFE2E8F0),
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.24),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: TextStyle(
              color: active ? Colors.white : AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (active)
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}
