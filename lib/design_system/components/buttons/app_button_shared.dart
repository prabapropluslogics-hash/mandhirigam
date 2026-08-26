import 'package:flutter/material.dart';

import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../feedback/app_loader.dart';

/// Shared button sizing used by primary / outlined / text buttons.
enum AppButtonSize { small, medium, large }

double appButtonHeight(AppButtonSize size) {
  return switch (size) {
    AppButtonSize.small => AppSizes.buttonHeightSm,
    AppButtonSize.medium => AppSizes.buttonHeightMd,
    AppButtonSize.large => AppSizes.buttonHeightLg,
  };
}

/// Shared label + optional icons / loading indicator for app buttons.
class AppButtonChild extends StatelessWidget {
  const AppButtonChild({
    super.key,
    required this.label,
    required this.isLoading,
    required this.isExpanded,
    required this.loaderColor,
    this.leadingIcon,
    this.trailingIcon,
  });

  final String label;
  final bool isLoading;
  final bool isExpanded;
  final Color loaderColor;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return AppLoader(
        size: AppSizes.iconMd,
        strokeWidth: AppSizes.loaderStrokeWidthCompact,
        color: loaderColor,
      );
    }

    return Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: AppSizes.iconMd),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        if (trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(trailingIcon, size: AppSizes.iconMd),
        ],
      ],
    );
  }
}
