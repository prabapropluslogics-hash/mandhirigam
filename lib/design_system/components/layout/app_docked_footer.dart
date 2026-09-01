import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Sticky bottom action region with safe-area padding.
class AppDockedFooter extends StatelessWidget {
  const AppDockedFooter({
    super.key,
    required this.child,
    this.backgroundColor,
  });

  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor ??
          AppColors.backgroundFor(Theme.of(context).brightness),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: AppInsets.page,
          child: child,
        ),
      ),
    );
  }
}
