import 'package:flutter/material.dart';

import '../../../../design_system/components/layout/app_card.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/models/profile_stats.dart';

class ReadingStreakCard extends StatelessWidget {
  const ReadingStreakCard({super.key, required this.streak});

  final ReadingStreak streak;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppInsets.pageHorizontal,
      child: AppCard(
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.featuredMid.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: const Padding(
                padding: AppInsets.sm,
                child: Icon(
                  AppIcons.flame,
                  color: AppColors.brandPrimary,
                  size: AppSizes.iconLg,
                ),
              ),
            ),
            const AppGap.md(axis: AppGapAxis.horizontal),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    streak.title,
                    style: AppTypography.label(context),
                  ),
                  const AppGap.xxs(),
                  Text(
                    streak.message,
                    style: AppTypography.helper(context),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                for (int i = 0; i < streak.totalDots; i++) ...[
                  if (i > 0) const AppGap.xs(axis: AppGapAxis.horizontal),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: i < streak.filledDots
                          ? AppColors.brandPrimary
                          : AppColors.neutral600,
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: AppSizes.badgeDot,
                      height: AppSizes.badgeDot,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
