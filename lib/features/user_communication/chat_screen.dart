import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String title;
  const ChatScreen({super.key, required this.chatId, required this.title});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _service = ChatService();
  final _input = TextEditingController();
  late Stream<QuerySnapshot<Map<String, dynamic>>> _messages;
  int _limit = 50;
  bool _sending = false;
  String? _retryId;
  String? _retryText;
  @override
  void initState() {
    super.initState();
    _watch();
  }

  void _watch() {
    _messages = _service.db
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(_limit)
        .snapshots();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (_sending || text.isEmpty) return;
    if (text.length > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keep messages under 2,000 characters.')),
      );
      return;
    }
    final id = _retryText == text && _retryId != null
        ? _retryId!
        : _service.db
              .collection('chats')
              .doc(widget.chatId)
              .collection('messages')
              .doc()
              .id;
    setState(() => _sending = true);
    try {
      await _service.send(widget.chatId, text, id);
      _retryId = null;
      _retryText = null;
      if (mounted) _input.clear();
    } catch (_) {
      _retryId = id;
      _retryText = text;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Message not sent. Check your connection and tap Send to retry.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F7F9),
    appBar: AppBar(title: Text(widget.title)),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _messages,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Could not load messages. Check access and connection.',
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == docs.length) {
                      return docs.length < _limit
                          ? const SizedBox.shrink()
                          : TextButton(
                              onPressed: () => setState(() {
                                _limit += 50;
                                _watch();
                              }),
                              child: const Text('Older messages'),
                            );
                    }
                    final message = docs[index].data();
                    final mine = message['senderId'] == _service.uid;
                    final date = (message['sentAt'] as Timestamp?)
                        ?.toDate()
                        .toLocal();
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * .78,
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: mine ? const Color(0xFFDCEBFF) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(message['text'] as String),
                            const SizedBox(height: 4),
                            Text(
                              date == null
                                  ? 'Sending...'
                                  : '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    enabled: !_sending,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                IconButton(
                  tooltip: 'Send',
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: Color(0xFF246BFD)),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
