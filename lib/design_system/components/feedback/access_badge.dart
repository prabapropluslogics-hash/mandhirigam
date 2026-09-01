import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import 'premium_badge.dart';

enum AccessKind { free, premium }

enum AccessBadgeVariant { filled, outline }

/// FREE / PREMIUM access chip used on details, library, and lists.
class AccessBadge extends StatelessWidget {
  const AccessBadge({
    super.key,
    required this.kind,
    this.variant = AccessBadgeVariant.filled,
    this.tone = PremiumBadgeTone.gold,
    this.compact = false,
    this.showIcon = true,
  });

  const AccessBadge.free({
    super.key,
    this.variant = AccessBadgeVariant.filled,
    this.compact = false,
    this.showIcon = true,
  })  : kind = AccessKind.free,
        tone = PremiumBadgeTone.gold;

  const AccessBadge.premium({
    super.key,
    this.variant = AccessBadgeVariant.filled,
    this.tone = PremiumBadgeTone.gold,
    this.compact = false,
    this.showIcon = true,
  }) : kind = AccessKind.premium;

  final AccessKind kind;
  final AccessBadgeVariant variant;
  final PremiumBadgeTone tone;
  final bool compact;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final bool isFree = kind == AccessKind.free;
    final bool isOutline = variant == AccessBadgeVariant.outline;
    final bool isDarkPremium =
        !isFree && !isOutline && tone == PremiumBadgeTone.dark;

    final Color background;
    final Color foreground;
    final Border? border;

    if (isOutline) {
      foreground = isFree ? AppColors.onSuccessContainer : AppColors.brandPrimary;
      background = Colors.transparent;
      border = Border.all(color: foreground, width: AppSizes.borderThin);
    } else if (isFree) {
      background = AppColors.successContainer;
      foreground = AppColors.onSuccessContainer;
      border = null;
    } else if (isDarkPremium) {
      background = AppColors.overlay;
      foreground = AppColors.neutral0;
      border = null;
    } else {
      background = AppColors.brandPrimary;
      foreground = AppColors.textOnBrand;
      border = null;
    }

    final IconData icon = isFree ? AppIcons.checkPlain : AppIcons.lock;
    final bool displayIcon = showIcon && !(isOutline && compact);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.chipBorder,
        border: border,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: compact ? AppSpacing.xxs : AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (displayIcon) ...[
              Icon(icon, size: AppSizes.iconXs, color: foreground),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              isFree ? 'FREE' : 'PREMIUM',
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
