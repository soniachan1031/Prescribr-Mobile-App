import 'package:flutter/material.dart';
import 'package:main/utils/theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../screens/profile_screen.dart';
import '../screens/home_screen.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final bool isCloseButton;
  final VoidCallback? onBack;

  // Static navigation lock to prevent overlapping navigation
  static bool _isNavigating = false;

  const TopBar({
    super.key,
    this.showBackButton = false,
    this.isCloseButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.lightBackgroundGrey,
      elevation: 4.0,
      iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
      leading: showBackButton || isCloseButton
          ? IconButton(
        icon: Icon(isCloseButton ? Icons.close : Icons.arrow_back),
        onPressed: onBack ?? () => Navigator.pop(context),
      )
          : null,
      actions: [
        if (!showBackButton && !isCloseButton)

        if (!showBackButton && !isCloseButton)
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.circleUser, size: 24),
            onPressed: () async {
              if (_isNavigating) return; // Prevent duplicate navigation
              _isNavigating = true;

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
              _isNavigating = false; // Reset navigation lock
            },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}