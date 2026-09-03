import 'package:flutter/material.dart';

import '../../../../design_system/components/feedback/app_confirm_dialog.dart';
import '../../../../design_system/components/feedback/app_empty_state.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/components/layout/app_section_header.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../routing/app_router.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/data/mock_catalog.dart';
import '../../../../shared/models/profile_stats.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_settings_list.dart';
import '../widgets/stats_grid.dart';
import '../widgets/weekly_activity_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _signedOut = false;

  ProfileStats get _stats => MockCatalog.profileStats;

  void _showUnavailable(String message) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onSignOut() async {
    final bool confirmed = await showAppConfirmDialog(
      context,
      title: 'Sign out',
      message: 'You will be signed out of this device.',
      confirmLabel: 'Sign out',
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() => _signedOut = true);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      safeAreaBottom: false,
      body: _signedOut
          ? const AppEmptyState(
              icon: AppIcons.logout,
              title: 'Signed out',
              message: 'You have been signed out of this device.',
            )
          : ListView(
              key: const Key('profile-scroll'),
              padding: const EdgeInsets.only(bottom: AppSpacing.massive),
              children: [
                const AppGap.lg(),
                ProfileHeader(
                  stats: _stats,
                  onEdit: () => _showUnavailable(
                    'Profile editing isn\'t available yet.',
                  ),
                ),
                const AppGap.xxl(),
                StatsGrid(
                  booksRead: _stats.booksRead,
                  dayStreak: _stats.dayStreak,
                  timeReading: _stats.timeReading,
                  pagesTurned: _stats.pagesTurned,
                ),
                const AppGap.xxl(),
                AppSectionHeader(
                  title: 'This week',
                  actionLabel: 'See stats',
                  serif: true,
                  onAction: () => _showUnavailable(
                    'Detailed stats aren\'t available yet.',
                  ),
                ),
                const AppGap.md(),
                const WeeklyActivityCard(activity: MockCatalog.weeklyActivity),
                const AppGap.xxl(),
                ProfileSettingsList(
                  onAccountPayment: () {
                    AppRouter.pushNamed(context, AppRoutes.subscription);
                  },
                  onNotifications: () => _showUnavailable(
                    'Notification settings aren\'t available yet.',
                  ),
                  onDownloads: () => _showUnavailable(
                    'Downloads & storage isn\'t available yet.',
                  ),
                  onReadingGoals: () => _showUnavailable(
                    'Reading goals aren\'t available yet.',
                  ),
                  onSignOut: _onSignOut,
                ),
              ],
            ),
    );
  }
}
