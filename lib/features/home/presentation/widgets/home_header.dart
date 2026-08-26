import 'package:flutter/material.dart';

import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/data/mock_catalog.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: AppInsets.pageHorizontal,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MockCatalog.greeting,
                  style: AppTypography.helper(context),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  MockCatalog.currentUserName,
                  style: AppTypography.display(context),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                AppIcons.notifications,
                size: AppSizes.iconLg,
                color: AppColors.textPrimaryFor(Theme.of(context).brightness),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: AppSizes.badgeDot,
                  height: AppSizes.badgeDot,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          CircleAvatar(
            radius: AppSizes.avatar / 2,
            backgroundColor: AppColors.avatarFallback,
            child: Text(
              'A',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.neutral0,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
