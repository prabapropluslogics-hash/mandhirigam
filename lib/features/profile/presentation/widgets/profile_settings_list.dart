import 'package:flutter/material.dart';

import '../../../../design_system/components/layout/app_divider.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/navigation/app_settings_tile.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';

class ProfileSettingsList extends StatelessWidget {
  const ProfileSettingsList({
    super.key,
    this.onAccountPayment,
    this.onNotifications,
    this.onDownloads,
    this.onReadingGoals,
    this.onSignOut,
  });

  final VoidCallback? onAccountPayment;
  final VoidCallback? onNotifications;
  final VoidCallback? onDownloads;
  final VoidCallback? onReadingGoals;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppInsets.pageHorizontal,
      child: Column(
        children: [
          AppSettingsTile(
            icon: AppIcons.creditCardOutline,
            label: 'Account & payment',
            onTap: onAccountPayment,
          ),
          const AppDivider(space: AppSizes.dividerThickness),
          AppSettingsTile(
            icon: AppIcons.notifications,
            label: 'Notifications',
            onTap: onNotifications,
          ),
          const AppDivider(space: AppSizes.dividerThickness),
          AppSettingsTile(
            icon: AppIcons.storage,
            label: 'Downloads & storage',
            onTap: onDownloads,
          ),
          const AppDivider(space: AppSizes.dividerThickness),
          AppSettingsTile(
            icon: AppIcons.clock,
            label: 'Reading goals',
            onTap: onReadingGoals,
          ),
          const AppDivider(space: AppSizes.dividerThickness),
          AppSettingsTile(
            icon: AppIcons.logout,
            label: 'Sign out',
            showChevron: false,
            color: AppColors.dangerSoft,
            onTap: onSignOut,
          ),
          const AppGap.lg(),
        ],
      ),
    );
  }
}
