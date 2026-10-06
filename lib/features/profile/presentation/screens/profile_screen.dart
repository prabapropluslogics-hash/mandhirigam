import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../design_system/theme/brand_theme.dart';
import '../../../../routing/app_router.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/ambient_background.dart';
import '../../../../shared/widgets/app_version_text.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../../state/auth_controller.dart';
import '../../../auth/presentation/widgets/google_continue_button.dart';
import '../../../settings/presentation/widgets/sign_out_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.onOpenLibrary});

  /// Switches the shell to the Library tab.
  final VoidCallback? onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    final AuthController auth = context.watch<AuthController>();

    return BrandTheme(
      child: AppScaffold(
        useSafeArea: false,
        body: Stack(
          children: [
            const Positioned.fill(child: AmbientBackground()),
            SafeArea(
              bottom: false,
              child: ListView(
                padding: AppInsets.page,
                children: [
                  const AppGap.lg(),
                  PageHeader(
                    title: 'Profile',
                    subtitle: auth.isAuthenticated ? null : 'Your account',
                  ),
                  const AppGap.xxl(),
                  if (auth.isAuthenticated)
                    _SignedInProfile(auth: auth, onOpenLibrary: onOpenLibrary)
                  else
                    const _GuestProfile(),
                  const AppGap.xxl(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  static const double _maxContentWidth = 420;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: Column(
          children: [
            const _GuestAvatar(),
            const AppGap.lg(),
            Text(
              'Browsing as guest',
              textAlign: TextAlign.center,
              style: AppTypography.bookTitle(
                context,
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const AppGap.sm(),
            Text(
              'Sign in to purchase books and keep them in your library.',
              style: AppTypography.bodySmall(context).copyWith(
                color: AppColors.textSecondaryDark,
              ),
              textAlign: TextAlign.center,
            ),
            const AppGap.xxl(),
            const _GuestBenefits(),
            const AppGap.xxl(),
            GoogleContinueButton(
              onPressed: () {
                AppRouter.pushNamed(
                  context,
                  AppRoutes.login,
                  arguments: 'Sign in to save your library.',
                );
              },
            ),
            const AppGap.xxl(),
            const _MenuCard(
              children: [
                _SettingsRow(),
                _AboutRow(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestAvatar extends StatelessWidget {
  const _GuestAvatar();

  static const double _size = 88;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surfaceMutedDark, AppColors.surfaceDark],
          ),
          border: Border.all(
            color: AppColors.brandPrimary.withOpacity(0.55),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandPrimary.withOpacity(0.16),
              blurRadius: 24,
            ),
          ],
        ),
        child: const Icon(
          AppIcons.person,
          size: AppSizes.iconXl + AppSizes.iconSm / 2,
          color: AppColors.brandAccent,
        ),
      ),
    );
  }
}

/// What signing in adds — limited to what the app actually supports.
class _GuestBenefits extends StatelessWidget {
  const _GuestBenefits();

  @override
  Widget build(BuildContext context) {
    final Divider divider = Divider(
      height: AppSpacing.xl,
      color: AppColors.brandPrimary.withOpacity(0.1),
    );
    return Container(
      padding: AppInsets.lg,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.7),
        borderRadius: AppRadii.cardBorder,
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SIGN IN TO UNLOCK',
            style: AppTypography.label(context).copyWith(
              color: AppColors.brandPrimary,
              fontSize: 12,
              letterSpacing: 1.8,
            ),
          ),
          const AppGap.lg(),
          const _BenefitRow(
            icon: AppIcons.premium,
            title: 'Purchase books',
            message: 'Buy premium titles inside the app.',
          ),
          divider,
          const _BenefitRow(
            icon: AppIcons.library,
            title: 'Personal library',
            message: 'Books you buy are kept together in your Library.',
          ),
          divider,
          const _BenefitRow(
            icon: AppIcons.person,
            title: 'Account access',
            message: 'Sign in with your Google account.',
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSizes.iconMd, color: AppColors.brandAccent),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.label(context).copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                message,
                style: AppTypography.caption(context).copyWith(
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SignedInProfile extends StatelessWidget {
  const _SignedInProfile({required this.auth, required this.onOpenLibrary});

  final AuthController auth;
  final VoidCallback? onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    final UserProfile user = auth.user!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadii.cardBorder,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surfaceMutedDark.withOpacity(0.85),
                    AppColors.surfaceDark.withOpacity(0.85),
                  ],
                ),
                border: Border.all(
                  color: AppColors.brandPrimary.withOpacity(0.18),
                ),
              ),
              child: Row(
                children: [
                  _UserAvatar(user: user),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bookTitle(
                            context,
                            fontSize: 21,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall(context).copyWith(
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const AppGap.xl(),
            _MenuCard(
              children: [
                _MenuRow(
                  icon: AppIcons.library,
                  title: 'My Library',
                  subtitle: 'Books you have purchased',
                  onTap: onOpenLibrary,
                ),
                const _SettingsRow(),
                const _AboutRow(),
              ],
            ),
            const AppGap.xl(),
            SignOutButton(
              key: const Key('sign-out'),
              onPressed: () => context.read<AuthController>().signOutLocal(),
            ),
            const AppGap.sm(),
            Text(
              'Signs out on this device only.',
              style: AppTypography.caption(context).copyWith(
                color: AppColors.textSecondaryDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  static const double _size = 68;

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final String? image = user.profileImageUrl;
    return ExcludeSemantics(
      child: Container(
        width: _size,
        height: _size,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.brandPrimary.withOpacity(0.7),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandPrimary.withOpacity(0.18),
              blurRadius: 18,
            ),
          ],
        ),
        child: CircleAvatar(
          backgroundColor: AppColors.surfaceElevatedDark,
          backgroundImage:
              image == null ? null : CachedNetworkImageProvider(image),
          child: image == null
              ? Text(
                  user.initials,
                  style: AppTypography.bookTitle(
                    context,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: AppColors.brandAccent,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.75),
        borderRadius: AppRadii.cardBorder,
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.14)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: AppSpacing.lg + AppSizes.iconMd + AppSpacing.md,
                color: AppColors.brandPrimary.withOpacity(0.1),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(icon, size: AppSizes.iconMd, color: AppColors.brandAccent),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.label(context).copyWith(
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle!,
                          style: AppTypography.caption(context).copyWith(
                            color: AppColors.textSecondaryDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (onTap != null)
                  const Icon(
                    AppIcons.chevronRight,
                    size: AppSizes.iconMd,
                    color: AppColors.textSecondaryDark,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow();

  @override
  Widget build(BuildContext context) {
    return _MenuRow(
      icon: AppIcons.settings,
      title: 'Settings',
      subtitle: 'Reading and Home language',
      onTap: () => AppRouter.pushNamed(context, AppRoutes.settings),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow();

  @override
  Widget build(BuildContext context) {
    return _MenuRow(
      icon: AppIcons.info,
      title: 'About ${AppConstants.appName}',
      trailing: AppVersionText(
        prefix: 'Version ',
        style: AppTypography.caption(context).copyWith(
          color: AppColors.textSecondaryDark,
        ),
      ),
    );
  }
}
