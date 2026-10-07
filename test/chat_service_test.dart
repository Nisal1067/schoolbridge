import 'package:flutter_test/flutter_test.dart';
import 'package:schoolbridge/features/user_communication/chat_service.dart';

void main() {
  test('One teacher-parent pair always resolves to the same conversation', () {
    expect(ChatService.chatId('teacher1', 'parent1'), 'teacher1_parent1');
    expect(ChatService.chatId('teacher1', 'parent1'),
        ChatService.chatId('teacher1', 'parent1'));
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
