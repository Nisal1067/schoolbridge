import 'dart:io';
import 'dart:typed_data';

Future<void> downloadPdfBytes(Uint8List bytes, String filename) async {
  final file = File(filename);
  await file.writeAsBytes(bytes);
}
