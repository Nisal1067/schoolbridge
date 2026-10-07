import 'package:flutter/material.dart';
import '../../../auth/widgets/logout_button.dart';

class SchoolBridgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onLeadingPressed;
  final VoidCallback? onNotificationPressed;
  final List<Widget>? actions;
  final bool showLogout;

  const SchoolBridgeAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.onLeadingPressed,
    this.onNotificationPressed,
    this.actions,
    this.showLogout = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleSpacing: showBackButton ? 0 : 16,
      shape: const Border(
        bottom: BorderSide(
          color: Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      leading: IconButton(
        icon: Icon(
          showBackButton
              ? Icons.arrow_back_ios_new_rounded
              : Icons.menu_rounded,
          color: const Color(0xFF1E293B),
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
          color: Color(0xFF1E293B),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: actions ??
          [
            if (onNotificationPressed != null)
              IconButton(
                tooltip: 'Notifications',
                onPressed: onNotificationPressed,
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF1E293B),
                ),
              ),
            if (showLogout) const LogoutButton(),
            const SizedBox(width: 4),
          ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

