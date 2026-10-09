import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
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
  static const _blue = AppColors.primary;
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
    backgroundColor: AppColors.background,
    appBar: PreferredSize(
      preferredSize: const Size.fromHeight(104),
      child: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryDark,
                AppColors.primary,
                AppColors.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 16, 16),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white24),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.title.isEmpty
                          ? '?'
                          : widget.title[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Parent-teacher conversation',
                          style: TextStyle(
                            color: Color(0xD9FFFFFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Conversation',
                    onPressed: () {},
                    icon: const Icon(
                      Icons.verified_user_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.background, Color(0xFFF8FAFC)],
        ),
      ),
      child: SafeArea(
        top: false,
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
                          horizontal: 16,
                          vertical: 22,
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
                              ? (docs[index + 1].data()['sentAt']
                                      as Timestamp?)
                                  ?.toDate()
                                  .toLocal()
                              : null;
                          final newDay =
                              date != null &&
                              !DateUtils.isSameDay(date, previous);
                          return Column(
                            children: [
                              if (newDay) _datePill(date),
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
            backgroundColor: const Color(0xFFDBEAFE),
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

  Widget _datePill(DateTime date) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        DateUtils.isSameDay(date, DateTime.now())
            ? 'Today'
            : '${date.day}/${date.month}/${date.year}',
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w700,
        ),
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
          maxWidth: (MediaQuery.sizeOf(context).width * .76).clamp(0, 560),
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: blueBubble
              ? const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: blueBubble ? null : Colors.white,
          border: blueBubble ? null : Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(mine ? 22 : 7),
            bottomRight: Radius.circular(mine ? 7 : 22),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
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
                    color: blueBubble ? Colors.white : const Color(0xFF1E293B),
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
                    fontWeight: FontWeight.w600,
                    color: blueBubble
                        ? Colors.white70
                        : const Color(0xFF64748B),
                  ),
                ),
                if (mine) ...[
                  const SizedBox(width: 5),
                  Icon(
                    pending ? Icons.schedule : Icons.done_all_rounded,
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
    margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_file != null)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                if ((_file!.extension ?? '').toLowerCase() == 'png' ||
                    (_file!.extension ?? '').toLowerCase().startsWith('jp'))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _fileBytes!,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) =>
                          const Icon(Icons.broken_image_outlined),
                    ),
                  )
                else
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.description_outlined, color: _blue),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _file!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
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
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        if (_sending && _file != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(value: _progress),
            ),
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
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(15),
              ),
              child: IconButton(
                tooltip: 'Attach file',
                onPressed: _sending || _picking || _uploaded != null
                    ? null
                    : _pick,
                icon: const Icon(
                  Icons.attach_file_rounded,
                  color: Color(0xFF64748B),
                  size: 21,
                ),
              ),
            ),
            const SizedBox(width: 10),
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
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 46,
              height: 46,
              child: IconButton.filled(
                tooltip: 'Send message',
                style: IconButton.styleFrom(
                  backgroundColor: _blue,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
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
