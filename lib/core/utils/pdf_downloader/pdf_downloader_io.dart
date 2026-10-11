import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

Future<void> downloadPdfBytes(Uint8List bytes, String filename) async {
  final sanitized = filename
      .replaceAll(RegExp(r'[\\/\x00-\x1F]'), '_')
      .replaceAll(RegExp(r'\s+'), '_');
  final dot = sanitized.lastIndexOf('.');
  final name = dot > 0 ? sanitized.substring(0, dot) : sanitized;
  final extension = dot > 0 ? sanitized.substring(dot + 1) : 'pdf';

  if (Platform.isIOS) {
    await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      fileExtension: extension,
      mimeType: MimeType.pdf,
    );
    return;
  }

  await FileSaver.instance.saveToDownloads(
    name: name,
    bytes: bytes,
    fileExtension: extension,
    mimeType: MimeType.pdf,
  );
}
