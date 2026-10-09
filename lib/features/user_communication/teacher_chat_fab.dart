import 'package:flutter/material.dart';

import 'communication_screen.dart';

/// Bottom padding for scrollable teacher screens, so the last item can scroll
/// clear of [TeacherChatFab] instead of being hidden underneath it.
const double kTeacherFabClearance = 88;

/// Opens the parent-teacher chat.
Future<void> openTeacherChat(BuildContext context) {
  return Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CommunicationScreen()),
  );
}

/// Floating quick-access button for the parent-teacher chat.
///
/// Add it as the `floatingActionButton` of every teacher-side [Scaffold].
/// It is not added to the chat screen itself.
class TeacherChatFab extends StatelessWidget {
  /// Lifts the button above a fixed bottom bar (for example a Save button).
  final double bottomOffset;

  const TeacherChatFab({super.key, this.bottomOffset = 0});

  @override
  Widget build(BuildContext context) {
    // Hide while the keyboard is open so it never sits on top of a text field.
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomOffset),
      child: FloatingActionButton(
        // One shared tag keeps the button steady when screens are pushed.
        heroTag: 'teacher_chat_fab',
        tooltip: 'Parent-Teacher Chat',
        backgroundColor: const Color(0xFF246BFD),
        foregroundColor: Colors.white,
        onPressed: () => openTeacherChat(context),
        child: const Icon(Icons.chat_bubble_rounded),
      ),
    );
  }
}
