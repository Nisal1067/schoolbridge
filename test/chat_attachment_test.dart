import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schoolbridge/features/user_communication/chat_attachment.dart';
import 'package:schoolbridge/features/user_communication/pdf_preview.dart';

void main() {
  test('non-web preview preserves the existing save fallback', () {
    expect(PdfPreview.reserve(), isNull);
  });

  testWidgets('PDF card has a preview tap and a separate download action', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ChatAttachment(
            attachment: {
              'provider': 'cloudinary',
              'path': 'chats/chat/sender/message/attachment',
              'name': 'example.pdf',
              'contentType': 'application/pdf',
              'size': 1024,
            },
          ),
        ),
      ),
    );
    expect(find.text('example.pdf'), findsOneWidget);
    expect(find.byTooltip('Download attachment'), findsOneWidget);
    final card = tester.widgetList<InkWell>(find.byType(InkWell));
    expect(card.any((widget) => widget.onTap != null), isTrue);
    expect(tester.takeException(), isNull);
  });
}
