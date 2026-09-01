import 'package:flutter/material.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/data/mock_catalog.dart';
import '../../../../shared/models/profile_stats.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.stats,
    this.onEdit,
  });

  final ProfileStats stats;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppInsets.pageHorizontal,
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSizes.avatarLg / 2,
            backgroundColor: AppColors.avatarFallback,
            child: Text(
              stats.initial,
              style: AppTypography.bookTitle(
                context,
                fontSize: 28,
                color: AppColors.neutral0,
              ),
            ),
          ),
          const AppGap.md(axis: AppGapAxis.horizontal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MockCatalog.currentUserName,
                  style: AppTypography.bookTitle(context, fontSize: 22),
                ),
                const AppGap.xs(),
                if (stats.isPremium)
                  Row(
                    children: [
                      const Icon(
                        AppIcons.premium,
                        size: AppSizes.iconSm,
                        color: AppColors.brandPrimary,
                      ),
                      const AppGap.xs(axis: AppGapAxis.horizontal),
                      Text(
                        stats.memberLabel,
                        style: AppTypography.helper(context).copyWith(
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          AppIconButton(
            icon: AppIcons.edit,
            tooltip: 'Edit profile',
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}
