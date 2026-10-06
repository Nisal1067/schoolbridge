import 'package:flutter/material.dart';

class SchoolBridgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onLeadingPressed;
  final VoidCallback? onNotificationPressed;

  const SchoolBridgeAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.onLeadingPressed,
    this.onNotificationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF2563EB),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          showBackButton
              ? Icons.arrow_back_ios_new_rounded
              : Icons.menu_rounded,
          color: Colors.white,
          size: 22,
        ),
        onPressed: onLeadingPressed ??
            () {
              if (showBackButton) {
                Navigator.of(context).maybePop();
              } else {
                Scaffold.maybeOf(context)?.openDrawer();
              }
            },
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 18),
          child: GestureDetector(
            onTap: onNotificationPressed,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
