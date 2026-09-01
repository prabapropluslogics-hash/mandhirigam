import 'package:flutter/material.dart';

import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/components/layout/app_section_header.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../routing/app_router.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/data/mock_catalog.dart';
import '../../../../shared/models/profile_stats.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_settings_list.dart';
import '../widgets/stats_grid.dart';
import '../widgets/weekly_activity_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileStats stats = MockCatalog.profileStats;

    return AppScaffold(
      safeAreaBottom: false,
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        children: [
          const AppGap.lg(),
          ProfileHeader(
            stats: stats,
            onEdit: () {},
          ),
          const AppGap.xxl(),
          StatsGrid(
            booksRead: stats.booksRead,
            dayStreak: stats.dayStreak,
            timeReading: stats.timeReading,
            pagesTurned: stats.pagesTurned,
          ),
          const AppGap.xxl(),
          AppSectionHeader(
            title: 'This week',
            actionLabel: 'See stats',
            serif: true,
            onAction: () {},
          ),
          const AppGap.md(),
          const WeeklyActivityCard(activity: MockCatalog.weeklyActivity),
          const AppGap.xxl(),
          ProfileSettingsList(
            onAccountPayment: () {
              AppRouter.pushNamed(context, AppRoutes.subscription);
            },
            onNotifications: () {},
            onDownloads: () {},
            onReadingGoals: () {},
            onSignOut: () {},
          ),
        ],
      ),
    );
  }
}
