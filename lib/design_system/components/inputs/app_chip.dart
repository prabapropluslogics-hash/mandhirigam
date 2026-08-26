import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';

enum AppChipVariant { surface, goldFilled, goldOutline, inverted }

/// Pill chip used for recent searches, filters, and access/genre options.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
    this.leadingIcon,
    this.variant = AppChipVariant.surface,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final IconData? leadingIcon;
  final AppChipVariant variant;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Brightness brightness = Theme.of(context).brightness;

    final Color background;
    final Color foreground;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case AppChipVariant.goldFilled:
        background = colors.primary;
        foreground = colors.onPrimary;
      case AppChipVariant.goldOutline:
        background = Colors.transparent;
        foreground = AppColors.textPrimaryFor(brightness);
        border = BorderSide(
          color: colors.primary,
          width: AppSizes.borderMedium,
        );
      case AppChipVariant.inverted:
        background = AppColors.neutral0;
        foreground = AppColors.textPrimary;
      case AppChipVariant.surface:
        if (selected) {
          background = AppColors.neutral0;
          foreground = AppColors.textPrimary;
        } else {
          background = AppColors.surfaceMutedFor(brightness);
          foreground = AppColors.textPrimaryFor(brightness);
        }
    }

    return Material(
      color: background,
      shape: StadiumBorder(side: border),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.chipHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, size: AppSizes.iconSm, color: foreground),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: foreground,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
