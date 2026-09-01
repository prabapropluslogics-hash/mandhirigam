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
    this.backgroundColor,
    this.disabled = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double iconSize;
  final Color? color;
  final Color? backgroundColor;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final Widget button = IconButton(
      onPressed: disabled ? null : onPressed,
      icon: Icon(icon, size: iconSize),
      color: color,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: AppSizes.iconButtonTapTarget,
        minHeight: AppSizes.iconButtonTapTarget,
      ),
    );

    if (backgroundColor == null) {
      return SizedBox(
        width: AppSizes.iconButtonTapTarget,
        height: AppSizes.iconButtonTapTarget,
        child: button,
      );
    }

    return SizedBox(
      width: AppSizes.iconButtonTapTarget,
      height: AppSizes.iconButtonTapTarget,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: button,
      ),
    );
  }
}
