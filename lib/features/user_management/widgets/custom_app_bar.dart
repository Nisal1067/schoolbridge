import 'package:flutter/material.dart';
import '../../../auth/widgets/logout_button.dart';
import '../../../core/theme/app_theme.dart';

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
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleSpacing: showBackButton ? 0 : 16,
      leading: IconButton(
        icon: Icon(
          showBackButton
              ? Icons.arrow_back_ios_new_rounded
              : Icons.menu_rounded,
          color: AppColors.textDark,
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
          color: AppColors.textDark,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
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

