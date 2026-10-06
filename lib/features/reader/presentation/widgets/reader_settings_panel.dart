import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/widgets/segmented_choice.dart';
import '../../state/reader_preferences.dart';
import '../reader_palette.dart';

/// Text size, theme, line spacing and width controls. Used by the reader's
/// settings sheet and the Settings screen; changes apply immediately.
class ReaderSettingsPanel extends StatelessWidget {
  const ReaderSettingsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final ReaderPreferences prefs = context.watch<ReaderPreferences>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Label(
          'Text size',
          trailing: prefs.fontSize.toStringAsFixed(0),
        ),
        const AppGap.xs(),
        _FontSizeSlider(prefs: prefs),
        const AppGap.lg(),
        const _Label('Reading theme'),
        const AppGap.sm(),
        Row(
          children: [
            for (final ReaderThemeMode mode in ReaderThemeMode.values) ...[
              if (mode != ReaderThemeMode.values.first)
                const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ThemeSwatch(
                  mode: mode,
                  selected: prefs.theme == mode,
                  onTap: () => prefs.setTheme(mode),
                ),
              ),
            ],
          ],
        ),
        const AppGap.lg(),
        const _Label('Line spacing'),
        const AppGap.sm(),
        SegmentedChoice<ReaderLineHeight>(
          values: ReaderLineHeight.values,
          selected: prefs.lineHeight,
          labelOf: (ReaderLineHeight v) => v.label,
          onSelected: prefs.setLineHeight,
        ),
        const AppGap.lg(),
        const _Label('Reading width'),
        const AppGap.sm(),
        SegmentedChoice<ReaderWidth>(
          values: ReaderWidth.values,
          selected: prefs.width,
          labelOf: (ReaderWidth v) => v.label,
          onSelected: prefs.setWidth,
        ),
      ],
    );
  }
}

/// Opens [ReaderSettingsPanel] in a compact bottom sheet.
Future<void> showReaderSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surfaceDark,
    barrierColor: AppColors.overlay.withOpacity(0.3),
    shape: RoundedRectangleBorder(borderRadius: AppRadii.bottomSheetBorder),
    builder: (BuildContext sheetContext) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHandle(),
              const AppGap.lg(),
              Text(
                'Reading settings',
                style: AppTypography.bookTitle(
                  sheetContext,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const AppGap.xs(),
              Text(
                'Saved on this device.',
                style: AppTypography.caption(sheetContext).copyWith(
                  color: AppColors.textSecondaryDark,
                ),
              ),
              const AppGap.xl(),
              const ReaderSettingsPanel(),
            ],
          ),
        ),
      );
    },
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: AppSizes.bottomSheetHandleWidth,
        height: AppSizes.bottomSheetHandleHeight,
        decoration: BoxDecoration(
          color: AppColors.neutral600,
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = AppTypography.caption(context).copyWith(
      color: AppColors.textSecondaryDark,
      letterSpacing: 1.1,
      fontWeight: FontWeight.w600,
    );
    return Row(
      children: [
        Expanded(child: Text(text.toUpperCase(), style: style)),
        if (trailing != null)
          Text(
            trailing!,
            style: AppTypography.label(context).copyWith(
              color: AppColors.brandAccent,
            ),
          ),
      ],
    );
  }
}

class _FontSizeSlider extends StatelessWidget {
  const _FontSizeSlider({required this.prefs});

  final ReaderPreferences prefs;

  @override
  Widget build(BuildContext context) {
    final TextStyle glyph = AppTypography.bookTitle(
      context,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimaryDark,
    );
    return Row(
      children: [
        ExcludeSemantics(child: Text('A', style: glyph.copyWith(fontSize: 14))),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.brandPrimary,
              inactiveTrackColor: AppColors.surfaceElevatedDark,
              thumbColor: AppColors.brandAccent,
              overlayColor: AppColors.brandPrimary.withOpacity(0.14),
              trackHeight: 3,
              showValueIndicator: ShowValueIndicator.never,
            ),
            child: Slider(
              value: prefs.fontSize,
              min: ReaderPreferences.minFontSize,
              max: ReaderPreferences.maxFontSize,
              divisions: (ReaderPreferences.maxFontSize -
                      ReaderPreferences.minFontSize)
                  .round(),
              semanticFormatterCallback: (double v) =>
                  'Text size ${v.round()}',
              onChanged: prefs.setFontSize,
              onChangeEnd: (_) => prefs.commitFontSize(),
            ),
          ),
        ),
        ExcludeSemantics(child: Text('A', style: glyph.copyWith(fontSize: 24))),
      ],
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ReaderThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ReaderPalette palette = ReaderPalette.of(mode);
    final BorderRadius radius = BorderRadius.circular(AppRadii.md);
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: '${mode.label} theme',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 56,
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[palette.background, palette.backgroundEnd],
                ),
                border: Border.all(
                  color: selected
                      ? AppColors.brandPrimary
                      : AppColors.borderDark,
                  width: selected ? AppSizes.borderThick : AppSizes.borderThin,
                ),
                boxShadow: selected
                    ? <BoxShadow>[
                        BoxShadow(
                          color: AppColors.brandPrimary.withOpacity(0.22),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                'Aa',
                style: AppTypography.bookTitle(
                  context,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: palette.text,
                ),
              ),
            ),
            const AppGap.xs(),
            Text(
              mode.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption(context).copyWith(
                color: selected
                    ? AppColors.brandAccent
                    : AppColors.textSecondaryDark,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
