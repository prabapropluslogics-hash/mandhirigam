import 'package:flutter/material.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/feedback/app_avatar.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            initial: stats.initial,
            size: AppSizes.avatarXl,
            useGradient: true,
            semanticLabel: stats.displayName,
          ),
          const AppGap.md(axis: AppGapAxis.horizontal),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.displayName,
                    style: AppTypography.bookTitle(context, fontSize: 26),
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
