import 'package:flutter/material.dart';

import '../../theme/app_sizes.dart';

/// Icon-only button with consistent tap target and icon size.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconSize = AppSizes.iconLg,
    this.color,
    this.disabled = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double iconSize;
  final Color? color;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSizes.iconButtonTapTarget,
      height: AppSizes.iconButtonTapTarget,
      child: IconButton(
        onPressed: disabled ? null : onPressed,
        icon: Icon(icon, size: iconSize),
        color: color,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: AppSizes.iconButtonTapTarget,
          minHeight: AppSizes.iconButtonTapTarget,
        ),
      ),
    );
  }
}
