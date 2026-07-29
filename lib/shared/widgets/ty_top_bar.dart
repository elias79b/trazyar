// lib/shared/widgets/ty_top_bar.dart
import 'package:flutter/material.dart';

class TyTopBar extends StatelessWidget implements PreferredSizeWidget {
  const TyTopBar({
    super.key,
    required this.title,
    required this.logoPath,
    this.onNotificationsPressed,
    this.onProfilePressed,
    this.onMenuPressed,
    this.showMenuButton = false,
  });

  final String title;
  final String logoPath;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onMenuPressed;
  final bool showMenuButton;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      leading: showMenuButton
          ? IconButton(
        onPressed: onMenuPressed,
        icon: const Icon(Icons.menu_rounded),
      )
          : null,
      title: Row(
        children: [
          Image.asset(
            logoPath,
            width: 36,
            height: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'اعلان‌ها',
          onPressed: onNotificationsPressed,
          icon: const Icon(Icons.notifications_none_rounded),
        ),
        IconButton(
          tooltip: 'پروفایل',
          onPressed: onProfilePressed,
          icon: const Icon(Icons.account_circle_outlined),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}