import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../routing/app_router.dart';
import '../../../../routing/app_routes.dart';
import '../../../../state/app_config_controller.dart';
import '../../../../state/auth_controller.dart';
import '../../../../state/library_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController auth = context.watch<AuthController>();
    final String appName =
        context.watch<AppConfigController>().config.branding.appName;

    return AppScaffold(
      safeAreaBottom: false,
      body: ListView(
        padding: AppInsets.page,
        children: [
          const AppGap.lg(),
          Text('Profile', style: AppTypography.pageTitle(context)),
          const AppGap.xxl(),
          if (auth.isAuthenticated)
            _SignedInProfile(auth: auth)
          else
            _GuestProfile(appName: appName),
        ],
      ),
    );
  }
}

class _GuestProfile extends StatelessWidget {
  const _GuestProfile({required this.appName});

  final String appName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.avatarFallback,
          child: Text(
            appName.isEmpty ? 'M' : appName[0],
            style: AppTypography.pageTitle(context)
                .copyWith(color: AppColors.neutral0),
          ),
        ),
        const AppGap.lg(),
        Text('Browsing as guest', style: AppTypography.sectionTitle(context)),
        const AppGap.sm(),
        Text(
          'Sign in to purchase books and keep them in your library.',
          style: AppTypography.helper(context),
          textAlign: TextAlign.center,
        ),
        const AppGap.xxl(),
        AppButton(
          label: 'Continue with Google',
          onPressed: () {
            AppRouter.pushNamed(
              context,
              AppRoutes.login,
              arguments: 'Sign in to save your library.',
            );
          },
        ),
      ],
    );
  }
}

class _SignedInProfile extends StatelessWidget {
  const _SignedInProfile({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final user = auth.user!;
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.avatarFallback,
          backgroundImage: user.profileImageUrl == null
              ? null
              : CachedNetworkImageProvider(user.profileImageUrl!),
          child: user.profileImageUrl == null
              ? Text(
                  user.initials,
                  style: AppTypography.pageTitle(context)
                      .copyWith(color: AppColors.neutral0),
                )
              : null,
        ),
        const AppGap.lg(),
        Text(user.name, style: AppTypography.sectionTitle(context)),
        const AppGap.xs(),
        Text(user.email, style: AppTypography.helper(context)),
        const AppGap.xxl(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Library'),
          subtitle: const Text('Lifetime purchases'),
          trailing: const Icon(Icons.chevron_right),
          minVerticalPadding: AppSizes.minTouchTarget / 4,
          onTap: () {},
        ),
        const AppGap.xxl(),
        AppOutlinedButton(
          key: const Key('sign-out'),
          label: 'Sign out',
          onPressed: () async {
            await context.read<AuthController>().signOutLocal();
            if (context.mounted) {
              context.read<LibraryController>().clearLocal();
            }
          },
        ),
        const AppGap.md(),
        Text(
          'Sign out clears this device session. There is no server logout.',
          style: AppTypography.caption(context),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
