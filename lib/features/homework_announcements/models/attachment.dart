import 'dart:typed_data';

/// Limits for homework files. The Supabase bucket enforces the same 10 MB cap
/// (see supabase_setup.sql).
const int kMaxAttachmentBytes = 10 * 1024 * 1024;

/// Most files one homework (or one submission) can carry. firestore.rules
/// enforces the same number.
const int kMaxAttachments = 5;

const String kPdfType = 'application/pdf';
const String kJpegType = 'image/jpeg';
const String kPngType = 'image/png';

/// A file that is already uploaded to private file storage (Supabase).
///
/// Stored inside the homework (teacher reference files) or submission
/// (student files) document as an `attachments` list of maps. Only the
/// reference is stored: files cannot be opened from it directly. A short-lived
/// link is requested for each viewing (see AttachmentUrls).
class Attachment {
  final String name;

  /// Only set by an earlier, public version of the storage. New files have no
  /// link, because the bucket is private.
  final String url;

  /// Location inside the storage bucket, needed to delete the file later.
  final String path;
  final String contentType;
  final int size;

  const Attachment({
    required this.name,
    this.url = '',
    required this.path,
    required this.contentType,
    required this.size,
  });

  bool get isImage => contentType.startsWith('image/');
  bool get isPdf => contentType == kPdfType;

  Map<String, dynamic> toMap() => {
    'name': name,
    if (url.isNotEmpty) 'url': url,
    'path': path,
    'contentType': contentType,
    'size': size,
  };

  factory Attachment.fromMap(Map<String, dynamic> map) => Attachment(
    name: map['name'] as String? ?? 'File',
    url: map['url'] as String? ?? '',
    path: map['path'] as String? ?? '',
    contentType: map['contentType'] as String? ?? '',
    size: (map['size'] as num?)?.toInt() ?? 0,
  );

  /// Reads the `attachments` field of a Firestore document. Documents created
  /// before attachments existed have no such field, which gives an empty list.
  static List<Attachment> listFrom(dynamic value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map) Attachment.fromMap(Map<String, dynamic>.from(item)),
    ];
  }
}

/// A file the user has chosen but that is not uploaded yet.
class PickedAttachment {
  final String name;
  final Uint8List bytes;
  final String contentType;

  const PickedAttachment({
    required this.name,
    required this.bytes,
    required this.contentType,
  });

  int get size => bytes.length;
  bool get isImage => contentType.startsWith('image/');
}

/// Works out the real type from the first bytes of a file, so a renamed or
/// unsupported file is rejected whatever its extension says.
/// Returns null unless the file is a PDF, JPEG or PNG.
String? sniffContentType(Uint8List b) {
  if (b.length >= 4 &&
      b[0] == 0x25 &&
      b[1] == 0x50 &&
      b[2] == 0x44 &&
      b[3] == 0x46) {
    return kPdfType; // "%PDF"
  }
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
    return kJpegType;
  }
  if (b.length >= 8 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47 &&
      b[4] == 0x0D &&
      b[5] == 0x0A &&
      b[6] == 0x1A &&
      b[7] == 0x0A) {
    return kPngType;
  }
  return null;
}

/// Adds the right extension when the name has none (camera photos often
/// arrive without one) or has the wrong one.
String nameWithExtension(String name, String contentType) {
  final lower = name.toLowerCase();
  final String extension;
  final bool matches;
  if (contentType == kPdfType) {
    extension = 'pdf';
    matches = lower.endsWith('.pdf');
  } else if (contentType == kPngType) {
    extension = 'png';
    matches = lower.endsWith('.png');
  } else {
    extension = 'jpg';
    matches = lower.endsWith('.jpg') || lower.endsWith('.jpeg');
  }
  return matches ? name : '$name.$extension';
}

/// A file name that is safe to use as a Storage object name.
String safeStorageName(String name) {
  final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  return cleaned.length > 80 ? cleaned.substring(cleaned.length - 80) : cleaned;
}

/// "850 B", "120 KB", "2.4 MB".
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
