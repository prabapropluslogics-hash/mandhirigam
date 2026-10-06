import 'package:flutter/material.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/buttons/app_button_shared.dart';
import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';

/// Languages offered by the Home content filter. Deliberately narrower than
/// the catalogue (Hindi is not offered on Home yet); `code` matches the
/// existing `language` query value of the books API.
enum HomeLanguage {
  tamil('ta', 'தமிழ்'),
  english('en', 'English');

  const HomeLanguage(this.code, this.label);

  final String code;
  final String label;

  /// Home opens in Tamil, whatever the catalogue `defaultLanguage` says,
  /// until the reader picks another language on Home or in Settings.
  static const HomeLanguage initial = tamil;
}

/// Compact "தமிழ் ▾" pill that opens [showHomeLanguageSheet]. Dims and
/// ignores taps while [onTap] is null (e.g. during a Home reload).
class HomeLanguageSelector extends StatelessWidget {
  const HomeLanguageSelector({
    super.key,
    required this.language,
    required this.onTap,
  });

  final HomeLanguage language;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ShapeBorder shape = StadiumBorder(
      side: BorderSide(
        color: AppColors.brandPrimary.withOpacity(0.35),
        width: AppSizes.borderThin,
      ),
    );
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: 'Home language: ${language.label}',
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onTap == null ? 0.55 : 1,
        child: Material(
          color: AppColors.surfaceDark.withOpacity(0.7),
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSizes.buttonHeightSm,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppIcons.language,
                      size: AppSizes.iconSm,
                      color: AppColors.brandAccent.withOpacity(0.8),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      language.label,
                      style: AppTypography.label(context).copyWith(
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    const Icon(
                      AppIcons.expandMore,
                      size: AppSizes.iconMd,
                      color: AppColors.brandAccent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Returns the applied language, or `null` when dismissed or cancelled.
Future<HomeLanguage?> showHomeLanguageSheet(
  BuildContext context, {
  required HomeLanguage current,
}) {
  return showModalBottomSheet<HomeLanguage>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => _HomeLanguageSheet(initial: current),
  );
}

class _HomeLanguageSheet extends StatefulWidget {
  const _HomeLanguageSheet({required this.initial});

  final HomeLanguage initial;

  @override
  State<_HomeLanguageSheet> createState() => _HomeLanguageSheetState();
}

class _HomeLanguageSheetState extends State<_HomeLanguageSheet> {
  late HomeLanguage _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: AppInsets.lg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: AppSizes.bottomSheetHandleWidth,
                height: AppSizes.bottomSheetHandleHeight,
                decoration: BoxDecoration(
                  color: AppColors.neutral600,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
              ),
            ),
            const AppGap.lg(),
            Text(
              'Select Language',
              style: AppTypography.bookTitle(
                context,
                fontSize: 22,
                color: AppColors.textPrimaryDark,
              ),
            ),
            const AppGap.xs(),
            Text(
              'Books on Home will be shown in this language.',
              style: AppTypography.helper(context),
            ),
            const AppGap.lg(),
            for (final HomeLanguage language in HomeLanguage.values) ...[
              _LanguageOption(
                language: language,
                selected: language == _selected,
                onTap: () => setState(() => _selected = language),
              ),
              const AppGap.sm(),
            ],
            const AppGap.lg(),
            AppButton(
              label: 'Apply',
              size: AppButtonSize.large,
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: AppColors.textOnBrand,
              onPressed: () => Navigator.of(context).pop(_selected),
            ),
            const AppGap.xs(),
            Center(
              child: AppTextButton(
                label: 'Cancel',
                foregroundColor: AppColors.textSecondaryDark,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final HomeLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadii.md);
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: selected
            ? AppColors.brandPrimary.withOpacity(0.1)
            : AppColors.surfaceMutedDark,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected
                ? AppColors.brandPrimary.withOpacity(0.7)
                : AppColors.borderDark,
            width: AppSizes.borderThin,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                _RadioMark(selected: selected),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    language.label,
                    style: AppTypography.body(context).copyWith(
                      color: AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: AppSizes.iconMd,
      height: AppSizes.iconMd,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.brandAccent : AppColors.textSecondaryDark,
          width: AppSizes.borderMedium,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: selected ? AppSpacing.sm + AppSpacing.xxs : 0,
        height: selected ? AppSpacing.sm + AppSpacing.xxs : 0,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brandAccent,
        ),
      ),
    );
  }
}
