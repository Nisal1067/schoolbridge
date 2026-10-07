import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

class PdfPreview {
  final web.Window _tab;
  PdfPreview._(this._tab);

  // Reserve synchronously during the tap so popup blockers do not reject it.
  static PdfPreview? reserve() {
    final tab = web.window.open('about:blank', '_blank');
    if (tab == null) throw StateError('Allow pop-ups to view the PDF.');
    tab.opener = null;
    tab.document.title = 'Loading PDF...';
    return PdfPreview._(tab);
  }

  void show(Uint8List bytes) {
    if (_tab.closed) throw StateError('PDF preview was closed.');
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/pdf'),
    );
    final url = web.URL.createObjectURL(blob);
    try {
      _tab.location.replace(url);
    } catch (_) {
      web.URL.revokeObjectURL(url);
      rethrow;
    }
    // Keep the URL valid for the viewer's reload/save actions until tab closure.
    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_tab.closed) {
        web.URL.revokeObjectURL(url);
        timer.cancel();
      }
    });
  }

  void close() => _tab.close();
}
