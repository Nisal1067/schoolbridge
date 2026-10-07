import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';

import 'chat_service.dart';
import 'chat_attachment_api.dart';
import 'pdf_preview.dart';

class ChatAttachment extends StatefulWidget {
  final Map<String, dynamic> attachment;
  const ChatAttachment({super.key, required this.attachment});
  @override
  State<ChatAttachment> createState() => _ChatAttachmentState();
}

class _ChatAttachmentState extends State<ChatAttachment> {
  Future<Uint8List?>? _image;
  bool _saving = false;
  bool _opening = false;
  bool get _isPdf => widget.attachment['contentType'] == 'application/pdf';
  bool get _isImage =>
      (widget.attachment['contentType'] as String).startsWith('image/');
  Future<Uint8List?> _read() => widget.attachment['provider'] == 'cloudinary'
      ? ChatAttachmentApi.download(widget.attachment)
      : FirebaseStorage.instance
            .ref(widget.attachment['path'])
            .getData(ChatService.maxAttachmentSize);
  @override
  void initState() {
    super.initState();
    if (_isImage) _image = _read();
  }

  @override
  void didUpdateWidget(covariant ChatAttachment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attachment['path'] != widget.attachment['path']) {
      _image = _isImage ? _read() : null;
    }
  }

  Future<void> _openPdf() async {
    if (_opening) return;
    PdfPreview? preview;
    try {
      preview = PdfPreview.reserve();
      if (preview == null) {
        if (!_saving) await _save();
        return;
      }
      setState(() => _opening = true);
      final bytes = await _read();
      if (bytes == null || bytes.isEmpty) {
        throw StateError('Attachment unavailable');
      }
      preview.show(bytes);
    } catch (error) {
      preview?.close();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is StateError &&
                      error.message == 'Allow pop-ups to view the PDF.'
                  ? error.message
                  : 'Could not open PDF. Check your connection and access, then retry.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final bytes = await (_image ?? _read());
      if (bytes == null) throw StateError('Attachment unavailable');
      final name = (widget.attachment['name'] as String).replaceAll(
        RegExp(r'[\\/\x00-\x1F]'),
        '_',
      );
      final dot = name.lastIndexOf('.');
      final path = await FileSaver.instance.saveFile(
        name: dot > 0 ? name.substring(0, dot) : name,
        bytes: bytes,
        fileExtension: dot > 0 ? name.substring(dot + 1) : '',
        mimeType: MimeType.custom,
        customMimeType: widget.attachment['contentType'],
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Attachment saved: $path')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not download attachment. Check your connection and access.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (_isImage)
        SizedBox(
          width: 300,
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: FutureBuilder<Uint8List?>(
                future: _image,
                builder: (context, snapshot) {
                  if (snapshot.hasError ||
                      (snapshot.connectionState == ConnectionState.done &&
                          snapshot.data == null)) {
                    return Center(
                      child: IconButton(
                        tooltip: 'Retry image',
                        onPressed: () => setState(() => _image = _read()),
                        icon: const Icon(Icons.refresh),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  return InkWell(
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: InteractiveViewer(
                                child: Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                tooltip: 'Close preview',
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    child: Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      const SizedBox(height: 8),
      InkWell(
        onTap: _isPdf && !_opening ? _openPdf : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isImage) ...[
              if (_opening)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  widget.attachment['contentType'] == 'application/pdf'
                      ? Icons.picture_as_pdf_outlined
                      : Icons.description_outlined,
                  color: const Color(0xFF246BFD),
                ),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.attachment['name'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${((widget.attachment['size'] as num) / 1024).toStringAsFixed(0)} KB',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Download attachment',
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined, size: 20),
            ),
          ],
        ),
      ),
    ],
  );
}
