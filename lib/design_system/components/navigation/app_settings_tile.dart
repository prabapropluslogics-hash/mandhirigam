import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../layout/app_gap.dart';

/// Icon + label + optional chevron row used in profile and settings lists.
class AppSettingsTile extends StatelessWidget {
  const AppSettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.showChevron = true,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool showChevron;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color resolved = color ?? Theme.of(context).colorScheme.onSurface;
    final Color chevronColor = color ??
        AppColors.textSecondaryFor(Theme.of(context).brightness);

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Row(
              children: [
                Icon(icon, size: AppSizes.iconLg, color: resolved),
                const AppGap.md(axis: AppGapAxis.horizontal),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.body(context).copyWith(color: resolved),
                  ),
                ),
                if (showChevron)
                  Icon(
                    AppIcons.chevronRight,
                    size: AppSizes.iconLg,
                    color: chevronColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
