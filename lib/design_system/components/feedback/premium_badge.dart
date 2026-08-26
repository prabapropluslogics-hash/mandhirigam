import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';

enum PremiumBadgeTone { gold, dark }

/// PREMIUM lock badge used on featured cards, lists, and details.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({
    super.key,
    this.tone = PremiumBadgeTone.gold,
    this.compact = false,
  });

  final PremiumBadgeTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool isGold = tone == PremiumBadgeTone.gold;
    final Color background =
        isGold ? AppColors.brandPrimary : AppColors.overlay;
    final Color foreground =
        isGold ? AppColors.textOnBrand : AppColors.neutral0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.chipBorder,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: compact ? AppSpacing.xxs : AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.lock, size: AppSizes.iconXs, color: foreground),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'PREMIUM',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground,
                    letterSpacing: 0.8,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
