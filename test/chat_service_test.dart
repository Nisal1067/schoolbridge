import 'package:flutter_test/flutter_test.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:schoolbridge/features/user_communication/chat_attachment.dart';
import 'package:schoolbridge/features/user_communication/chat_service.dart';
import 'package:schoolbridge/features/user_communication/chat_attachment_api.dart';

void main() {
  test('Deleting a conversation hides old activity but not new messages', () {
    final deleted = Timestamp.fromMillisecondsSinceEpoch(2000);
    expect(
      ChatService.isConversationHidden(
        deleted,
        Timestamp.fromMillisecondsSinceEpoch(1000),
      ),
      isTrue,
    );
    expect(ChatService.isConversationHidden(deleted, deleted), isTrue);
    expect(
      ChatService.isConversationHidden(
        deleted,
        Timestamp.fromMillisecondsSinceEpoch(3000),
      ),
      isFalse,
    );
    expect(ChatService.isConversationHidden(null, deleted), isFalse);
    expect(ChatService.isConversationHidden(deleted, null), isTrue);
  });
  test('Attachment API uses authenticated chat-specific routes', () {
    final uri = ChatAttachmentApi.endpoint('teacher1_parent1', 'message1');
    expect(uri.path, '/chats/teacher1_parent1/attachments/message1');
    expect(
      ChatService.sendError(AttachmentApiException('PDF delivery blocked')),
      'PDF delivery blocked',
    );
  });
  test('Attachment failures explain setup, access and timeouts', () {
    expect(
      ChatService.sendError(TimeoutException('timeout')),
      contains('timed out'),
    );
    expect(
      ChatService.sendError(
        FirebaseException(plugin: 'firebase_storage', code: 'bucket-not-found'),
      ),
      contains('not set up'),
    );
    expect(
      ChatService.sendError(
        FirebaseException(plugin: 'firebase_storage', code: 'unauthorized'),
      ),
      contains('access denied'),
    );
  });
  testWidgets('Document attachments fit narrow and desktop layouts', (
    tester,
  ) async {
    for (final width in [240.0, 580.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: const ChatAttachment(
                  attachment: {
                    'path': 'chats/test/teacher/message/attachment',
                    'name': 'A_very_long_school_report_filename_for_the_current_term.pdf',
                    'size': 4096,
                    'contentType': 'application/pdf',
                  },
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byTooltip('Download attachment'), findsOneWidget);
      expect(find.text('4 KB'), findsOneWidget);
    }
  });
  test('Attachment validation permits supported files and enforces size', () {
    expect(ChatService.attachmentError('photo.JPG', 1024), isNull);
    expect(
      ChatService.attachmentError('lesson.pdf', ChatService.maxAttachmentSize),
      isNull,
    );
    expect(
      ChatService.attachmentError(
        'lesson.pdf',
        ChatService.maxAttachmentSize + 1,
      ),
      isNotNull,
    );
    expect(ChatService.attachmentError('empty.txt', 0), isNotNull);
    expect(ChatService.attachmentError('program.exe', 100), isNotNull);
  });
  test('One teacher-parent pair always resolves to the same conversation', () {
    expect(ChatService.chatId('teacher1', 'parent1'), 'teacher1_parent1');
    expect(
      ChatService.chatId('teacher1', 'parent1'),
      ChatService.chatId('teacher1', 'parent1'),
    );
  });

  test('Different teachers and parents have separate conversations', () {
    final ids = {
      ChatService.chatId('teacher1', 'parent1'),
      ChatService.chatId('teacher2', 'parent1'),
      ChatService.chatId('teacher1', 'parent2'),
    };
    expect(ids.length, 3);
  });
}
