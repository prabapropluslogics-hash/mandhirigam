import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
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
import '../../../../shared/widgets/ambient_background.dart';
import '../../../../shared/widgets/app_version_text.dart';
import '../../../../shared/widgets/segmented_choice.dart';
import '../../../../state/auth_controller.dart';
import '../../../home/presentation/widgets/home_language_selector.dart';
import '../../../home/state/home_language_preference.dart';
import '../../../reader/presentation/reader_palette.dart';
import '../../../reader/presentation/widgets/reader_paper.dart';
import '../../../reader/presentation/widgets/reader_settings_panel.dart';
import '../../../reader/state/reader_preferences.dart';
import '../widgets/sign_out_button.dart';

/// Reading, Home and app settings. Everything here is stored on the device.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const double _maxContentWidth = 560;

  @override
  Widget build(BuildContext context) {
    final AuthController auth = context.watch<AuthController>();
    final HomeLanguagePreference homeLanguage =
        context.watch<HomeLanguagePreference>();

    return BrandTheme(
      child: AppScaffold(
        useSafeArea: false,
        body: Stack(
          children: [
            const Positioned.fill(child: AmbientBackground()),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xs,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Row(
                      children: [
                        AppIconButton(
                          icon: AppIcons.back,
                          tooltip: 'Back',
                          iconSize: AppSizes.iconMd,
                          color: AppColors.textPrimaryDark,
                          onPressed: () => AppRouter.pop(context),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Semantics(
                          header: true,
                          child: Text(
                            'Settings',
                            style: AppTypography.bookTitle(
                              context,
                              fontSize: 26,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pageHorizontal,
                        AppSpacing.lg,
                        AppSpacing.pageHorizontal,
                        AppSpacing.huge,
                      ),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: _maxContentWidth,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _SectionTitle('Reading'),
                                const _Card(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _ReaderPreview(),
                                      AppGap.xl(),
                                      ReaderSettingsPanel(),
                                    ],
                                  ),
                                ),
                                const AppGap.xxl(),
                                const _SectionTitle('Home'),
                                _Card(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      const _RowLabel(
                                        title: 'Home language',
                                        subtitle:
                                            'Books on Home are shown in this language.',
                                      ),
                                      const AppGap.md(),
                                      SegmentedChoice<HomeLanguage>(
                                        values: HomeLanguage.values,
                                        selected: homeLanguage.language,
                                        labelOf: (HomeLanguage l) => l.label,
                                        onSelected: homeLanguage.select,
                                      ),
                                    ],
                                  ),
                                ),
                                const AppGap.xxl(),
                                const _SectionTitle('App'),
                                _Card(
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: _RowLabel(title: 'Version'),
                                      ),
                                      AppVersionText(
                                        style: AppTypography.label(context)
                                            .copyWith(
                                          color: AppColors.textSecondaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (auth.isAuthenticated) ...[
                                  const AppGap.xxl(),
                                  const _SectionTitle('Account'),
                                  _Card(
                                    child: _AccountSection(auth: auth),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 1,
            color: AppColors.brandPrimary.withOpacity(0.8),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text.toUpperCase(),
            style: AppTypography.label(context).copyWith(
              color: AppColors.brandPrimary,
              fontSize: 12,
              letterSpacing: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppInsets.lg,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.75),
        borderRadius: AppRadii.cardBorder,
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.14)),
      ),
      child: child,
    );
  }
}

class _RowLabel extends StatelessWidget {
  const _RowLabel({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

/// A short classical Tamil line rendered with the current reader settings.
class _ReaderPreview extends StatelessWidget {
  const _ReaderPreview();

  static const String _sample =
      'அகர முதல எழுத்தெல்லாம் ஆதி\nபகவன் முதற்றே உலகு.';

  @override
  Widget build(BuildContext context) {
    final ReaderPreferences prefs = context.watch<ReaderPreferences>();
    final ReaderPalette palette = ReaderPalette.of(prefs.theme);
    final BorderRadius radius = BorderRadius.circular(AppRadii.md);
    return Semantics(
      label: 'Reader preview',
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(child: ReaderPaper(palette: palette)),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: palette.rule.withOpacity(0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview',
                    style: AppTypography.caption(context).copyWith(
                      color: palette.accent,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const AppGap.sm(),
                  Text(
                    _sample,
                    style: palette.readingStyle(prefs).body(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final String email = auth.user?.email ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RowLabel(
          title: 'Signed in with Google',
          subtitle: email.isEmpty ? null : email,
        ),
        const AppGap.lg(),
        SignOutButton(
          key: const Key('settings-sign-out'),
          onPressed: () => context.read<AuthController>().signOutLocal(),
        ),
        const AppGap.sm(),
        Text(
          'Signs out on this device only.',
          style: AppTypography.caption(context).copyWith(
            color: AppColors.textSecondaryDark,
          ),
        ),
      ],
    );
  }
}
