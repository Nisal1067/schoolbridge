import 'dart:typed_data';

import 'pdf_downloader_stub.dart'
    if (dart.library.html) 'pdf_downloader_web.dart'
    if (dart.library.io) 'pdf_downloader_io.dart' as impl;

Future<void> downloadPdf(Uint8List bytes, String filename) async {
  await impl.downloadPdfBytes(bytes, filename);
}
