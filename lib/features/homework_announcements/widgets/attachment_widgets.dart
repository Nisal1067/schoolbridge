import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/attachment.dart';
import '../services/attachment_service.dart';
import 'task_widgets.dart';

/// Opens a saved file: images in a zoomable viewer, PDFs in the device's PDF
/// app (or a browser tab on the web).
///
/// The bucket is private, so a short-lived link is requested first. The server
/// only gives one to people who are allowed to see the file.
Future<void> openAttachment(BuildContext context, Attachment file) async {
  if (file.isImage) {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _ImageViewerScreen(file: file)),
    );
    return;
  }
  String? url;
  try {
    url = await AttachmentUrls.instance.urlFor(file);
  } catch (_) {
    url = null;
  }
  var opened = false;
  if (url != null) {
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
  }
  if (!opened && context.mounted) {
    showTaskSnack(context, 'Could not open this file.');
  }
}

/// Read-only list of saved files, or [emptyText] when there are none.
class AttachmentList extends StatelessWidget {
  final List<Attachment> attachments;
  final String emptyText;

  const AttachmentList({
    super.key,
    required this.attachments,
    this.emptyText = 'No files attached.',
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return Text(
        emptyText,
        style: const TextStyle(fontSize: 14, color: TaskColors.grey),
      );
    }
    return Column(
      children: [
        for (final file in attachments)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AttachmentTile(file: file),
          ),
      ],
    );
  }
}

/// "Upload" box plus the files chosen so far.
///
/// Used by the teacher (reference files) and the student (homework files).
/// [saved] are files already uploaded, [pending] are chosen but not uploaded
/// yet. The screen owns both lists and uploads [pending] when it saves.
class AttachmentPickerSection extends StatelessWidget {
  final List<Attachment> saved;
  final List<PickedAttachment> pending;
  final ValueChanged<List<Attachment>> onSavedChanged;
  final ValueChanged<List<PickedAttachment>> onPendingChanged;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color fill;
  final bool enabled;

  const AttachmentPickerSection({
    super.key,
    required this.saved,
    required this.pending,
    required this.onSavedChanged,
    required this.onPendingChanged,
    this.title = 'Upload PDF or Images',
    this.subtitle = 'Max file size 10MB, up to 5 files',
    this.icon = Icons.file_upload_outlined,
    this.fill = TaskColors.blueSoft,
    this.enabled = true,
  });

  int get _count => saved.length + pending.length;

  Future<void> _add(BuildContext context) async {
    if (_count >= kMaxAttachments) {
      showTaskSnack(context, 'You can attach up to $kMaxAttachments files.');
      return;
    }
    var source = AttachmentSource.files;
    if (AttachmentPicker.hasPhotoSources) {
      final chosen = await showModalBottomSheet<AttachmentSource>(
        context: context,
        builder: (_) => const _SourceSheet(),
      );
      if (chosen == null) return;
      source = chosen;
    }
    final outcome = await AttachmentPicker.pick(
      source,
      maxFiles: kMaxAttachments - _count,
    );
    if (!context.mounted) return;
    if (outcome.files.isNotEmpty) {
      onPendingChanged([...pending, ...outcome.files]);
    }
    if (outcome.problems.isNotEmpty) {
      showTaskSnack(context, outcome.problems.join('\n'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DashedBox(
          padding: const EdgeInsets.symmetric(vertical: 22),
          fill: fill,
          onTap: enabled ? () => _add(context) : null,
          child: Column(
            children: [
              Icon(icon, color: TaskColors.blue),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: TaskColors.blue,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: TaskColors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        for (final file in saved)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AttachmentTile(
              file: file,
              onRemove: enabled
                  ? () => onSavedChanged(
                      saved.where((other) => other != file).toList(),
                    )
                  : null,
            ),
          ),
        for (final file in pending)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: PendingAttachmentTile(
              file: file,
              onRemove: enabled
                  ? () => onPendingChanged(
                      pending.where((other) => other != file).toList(),
                    )
                  : null,
            ),
          ),
      ],
    );
  }
}

/// A file that is already uploaded. Tap to open; [onRemove] adds an X button.
class AttachmentTile extends StatelessWidget {
  final Attachment file;
  final VoidCallback? onRemove;

  const AttachmentTile({super.key, required this.file, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return _FileRow(
      thumb: file.isImage
          ? _SignedImage(file: file, fit: BoxFit.cover, cacheWidth: 132)
          : const _TypeIcon(isPdf: true),
      name: file.name,
      detail: '${file.isPdf ? 'PDF' : 'Image'} - ${formatFileSize(file.size)}',
      trailing: onRemove == null
          ? const Icon(Icons.open_in_new, size: 18, color: TaskColors.grey)
          : IconButton(
              tooltip: 'Remove',
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 20, color: TaskColors.grey),
            ),
      onTap: () => openAttachment(context, file),
    );
  }
}

/// A file that was chosen but is not uploaded yet.
class PendingAttachmentTile extends StatelessWidget {
  final PickedAttachment file;
  final VoidCallback? onRemove;

  const PendingAttachmentTile({super.key, required this.file, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return _FileRow(
      thumb: file.isImage
          ? Image.memory(
              file.bytes,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              cacheWidth: 132,
              errorBuilder: (context, error, stackTrace) =>
                  const _TypeIcon(isPdf: false),
            )
          : const _TypeIcon(isPdf: true),
      name: file.name,
      detail: '${formatFileSize(file.size)} - uploads when you save',
      trailing: onRemove == null
          ? null
          : IconButton(
              tooltip: 'Remove',
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 20, color: TaskColors.grey),
            ),
    );
  }
}

class _FileRow extends StatelessWidget {
  final Widget thumb;
  final String name;
  final String detail;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _FileRow({
    required this.thumb,
    required this.name,
    required this.detail,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TaskColors.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(width: 44, height: 44, child: thumb),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TaskColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: TaskColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing! else const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final bool isPdf;
  const _TypeIcon({required this.isPdf});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isPdf ? TaskColors.redSoft : TaskColors.blueSoft,
      alignment: Alignment.center,
      child: Icon(
        isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
        color: isPdf ? TaskColors.red : TaskColors.blue,
      ),
    );
  }
}

class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, AttachmentSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(context, AttachmentSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Choose a PDF or file'),
            onTap: () => Navigator.pop(context, AttachmentSource.files),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// An image from the private bucket. Asks for a short-lived link, shows the
/// type icon while it loads or if the user may not see the file.
class _SignedImage extends StatefulWidget {
  final Attachment file;
  final BoxFit fit;
  final int? cacheWidth;
  final bool showLoading;

  const _SignedImage({
    required this.file,
    required this.fit,
    this.cacheWidth,
    this.showLoading = false,
  });

  @override
  State<_SignedImage> createState() => _SignedImageState();
}

class _SignedImageState extends State<_SignedImage> {
  late final Future<String?> _url = AttachmentUrls.instance.urlFor(widget.file);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _url,
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url != null) {
          return Image.network(
            url,
            fit: widget.fit,
            cacheWidth: widget.cacheWidth,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : _placeholder(loading: widget.showLoading),
            errorBuilder: (context, error, stackTrace) => _placeholder(),
          );
        }
        final waiting = snapshot.connectionState != ConnectionState.done;
        return _placeholder(loading: waiting && widget.showLoading);
      },
    );
  }

  Widget _placeholder({bool loading = false}) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return widget.showLoading
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Could not load this image.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          )
        : const _TypeIcon(isPdf: false);
  }
}

class _ImageViewerScreen extends StatelessWidget {
  final Attachment file;
  const _ImageViewerScreen({required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          file.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: _SignedImage(
            file: file,
            fit: BoxFit.contain,
            showLoading: true,
          ),
        ),
      ),
    );
  }
}
