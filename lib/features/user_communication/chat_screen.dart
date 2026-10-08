import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'chat_service.dart';
import 'chat_attachment.dart';

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
  bool _picking = false;
  double _progress = 0;
  String? _draftId;
  PlatformFile? _file;
  Uint8List? _fileBytes;
  Map<String, dynamic>? _uploaded;
  String? _error;
  static const _blue = Color(0xFF008CFF);
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

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _pick() async {
    setState(() => _picking = true);
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ChatService.attachmentTypes.keys.toList(),
      );
      if (!mounted || file == null) return;
      final size = await file.length();
      if (!mounted) return;
      final error = ChatService.attachmentError(file.name, size ?? 0);
      if (error != null) {
        _notice(error);
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final actualError = ChatService.attachmentError(file.name, bytes.length);
      if (actualError != null) {
        _notice(actualError);
        return;
      }
      setState(() {
        _file = file;
        _fileBytes = bytes;
        _uploaded = null;
        _draftId = null;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        _notice('Could not select the attachment. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (_sending || _picking || (text.isEmpty && _file == null)) return;
    if (text.length > 2000) {
      _notice('Keep messages under 2,000 characters.');
      return;
    }
    _draftId ??= _service.db
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc()
        .id;
    setState(() {
      _sending = true;
      _error = null;
      _progress = 0;
    });
    try {
      if (_file != null && _uploaded == null) {
        _uploaded = await _service.uploadAttachment(
          widget.chatId,
          _draftId!,
          _file!.name,
          _fileBytes!,
          (progress) {
            if (mounted) setState(() => _progress = progress);
          },
        );
      }
      await _service.send(
        widget.chatId,
        text,
        _draftId!,
        attachment: _uploaded,
      );
      if (!mounted) return;
      _input.clear();
      setState(() {
        _file = null;
        _fileBytes = null;
        _uploaded = null;
        _draftId = null;
      });
    } catch (error) {
      debugPrint('Chat send failed: $error');
      if (mounted) {
        setState(() => _error = ChatService.sendError(error));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _removeAttachment() async {
    setState(() => _picking = true);
    try {
      if (_draftId != null) {
        await _service.discardAttachment(widget.chatId, _draftId!);
      }
      if (!mounted) return;
      setState(() {
        _file = null;
        _fileBytes = null;
        _uploaded = null;
        _draftId = null;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        _notice('Could not remove this draft. Retry sending or removing it.');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: _blue,
      surfaceTintColor: _blue,
      foregroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 126,
      centerTitle: true,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: .55)),
            ),
            child: CircleAvatar(
              radius: 27,
              backgroundColor: Colors.white,
              child: Text(
                widget.title.isEmpty ? '?' : widget.title[0].toUpperCase(),
                style: const TextStyle(
                  color: _blue,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 3),
          const Text(
            'SchoolBridge',
            style: TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(22),
        child: Container(
          height: 22,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
        ),
      ),
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _messages,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _empty(
                        Icons.cloud_off_outlined,
                        'Messages unavailable',
                        'Check your connection and chat access.',
                        retry: true,
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return _empty(
                        Icons.forum_outlined,
                        'Start a conversation',
                        widget.title,
                      );
                    }
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      itemCount: docs.length + 1,
                      itemBuilder: (context, index) {
                        if (index == docs.length) {
                          return docs.length < _limit
                              ? const SizedBox.shrink()
                              : Center(
                                  child: TextButton.icon(
                                    onPressed: () => setState(() {
                                      _limit += 50;
                                      _watch();
                                    }),
                                    icon: const Icon(Icons.history),
                                    label: const Text('Older messages'),
                                  ),
                                );
                        }
                        final message = docs[index].data();
                        final date = (message['sentAt'] as Timestamp?)
                            ?.toDate()
                            .toLocal();
                        final previous = index + 1 < docs.length
                            ? (docs[index + 1].data()['sentAt'] as Timestamp?)
                                  ?.toDate()
                                  .toLocal()
                            : null;
                        final newDay =
                            date != null &&
                            !DateUtils.isSameDay(date, previous);
                        return Column(
                          children: [
                            if (newDay)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                child: Text(
                                  DateUtils.isSameDay(date, DateTime.now())
                                      ? 'Today'
                                      : '${date.day}/${date.month}/${date.year}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            _bubble(
                              message,
                              date,
                              docs[index].metadata.hasPendingWrites,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              _composer(),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _empty(
    IconData icon,
    String title,
    String subtitle, {
    bool retry = false,
  }) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: const Color(0xFFE8F0FF),
            child: Icon(icon, size: 30, color: _blue),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          if (retry)
            TextButton.icon(
              onPressed: () => setState(_watch),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
        ],
      ),
    ),
  );

  Widget _bubble(Map<String, dynamic> message, DateTime? date, bool pending) {
    final mine = message['senderId'] == _service.uid;
    final text = message['text'] as String? ?? '';
    final blueBubble = mine && message['attachment'] == null;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.sizeOf(context).width * .78).clamp(0, 580),
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: blueBubble ? _blue : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(mine ? 20 : 5),
            bottomRight: Radius.circular(mine ? 5 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message['attachment'] is Map)
              ChatAttachment(
                attachment: Map<String, dynamic>.from(message['attachment']),
              ),
            if (text.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  top: message['attachment'] == null ? 0 : 10,
                ),
                child: SelectableText(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: blueBubble ? Colors.white : const Color(0xFF4B5563),
                  ),
                ),
              ),
            const SizedBox(height: 7),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  date == null
                      ? 'Sending'
                      : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: blueBubble
                        ? Colors.white70
                        : const Color(0xFF64748B),
                  ),
                ),
                if (mine) ...[
                  const SizedBox(width: 5),
                  Icon(
                    pending ? Icons.schedule : Icons.check,
                    size: 14,
                    color: blueBubble
                        ? Colors.white70
                        : const Color(0xFF64748B),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _composer() => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 20,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_file != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                if ((_file!.extension ?? '').toLowerCase() == 'png' ||
                    (_file!.extension ?? '').toLowerCase().startsWith('jp'))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      _fileBytes!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) =>
                          const Icon(Icons.broken_image_outlined),
                    ),
                  )
                else
                  const Icon(Icons.description_outlined, color: _blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _file!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${(_fileBytes!.length / 1024).toStringAsFixed(0)} KB',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove attachment',
                  onPressed: _sending || _picking ? null : _removeAttachment,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        if (_sending && _file != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LinearProgressIndicator(value: _progress),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 18,
                  color: Color(0xFFC03943),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFC03943),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _sending ? null : _send,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Attach file',
              onPressed: _sending || _picking || _uploaded != null
                  ? null
                  : _pick,
              icon: const Icon(Icons.attach_file, color: Color(0xFF64748B)),
            ),
            Expanded(
              child: TextField(
                controller: _input,
                enabled: !_sending && _uploaded == null,
                minLines: 1,
                maxLines: 5,
                onChanged: (_) {
                  _draftId = null;
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Write a message...',
                  filled: true,
                  fillColor: const Color(0xFFF7F7F7),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton.filled(
                tooltip: 'Send message',
                style: IconButton.styleFrom(
                  backgroundColor: _blue,
                  shape: const CircleBorder(),
                ),
                onPressed:
                    _sending ||
                        _picking ||
                        (_input.text.trim().isEmpty && _file == null)
                    ? null
                    : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 21),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
