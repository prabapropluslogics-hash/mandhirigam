import 'package:flutter/material.dart';

import '../../../design_system/theme/app_colors.dart';
import '../../../design_system/theme/app_theme.dart';
import '../../../design_system/theme/app_typography.dart';
import '../state/reader_preferences.dart';
import 'widgets/rich_text_document_view.dart';

/// Colors of the reading page for one reader theme. The app chrome around
/// the page stays dark in every theme.
class ReaderPalette {
  const ReaderPalette._({
    required this.mode,
    required this.brightness,
    required this.background,
    required this.backgroundEnd,
    required this.text,
    required this.secondaryText,
    required this.accent,
    required this.rule,
    required this.manuscript,
  });

  factory ReaderPalette.of(ReaderThemeMode mode) {
    switch (mode) {
      case ReaderThemeMode.olaichuvadi:
        return const ReaderPalette._(
          mode: ReaderThemeMode.olaichuvadi,
          brightness: Brightness.light,
          background: AppColors.readerParchment,
          backgroundEnd: AppColors.readerParchmentDeep,
          text: AppColors.readerInk,
          secondaryText: AppColors.readerInkSoft,
          accent: AppColors.readerGoldDeep,
          rule: AppColors.readerRule,
          manuscript: true,
        );
      case ReaderThemeMode.dark:
        return const ReaderPalette._(
          mode: ReaderThemeMode.dark,
          brightness: Brightness.dark,
          background: AppColors.readerDark,
          backgroundEnd: AppColors.readerDarkDeep,
          text: AppColors.splashTagline,
          secondaryText: AppColors.textSecondaryDark,
          accent: AppColors.brandPrimary,
          rule: AppColors.brandSecondary,
          manuscript: false,
        );
      case ReaderThemeMode.light:
        return const ReaderPalette._(
          mode: ReaderThemeMode.light,
          brightness: Brightness.light,
          background: AppColors.readerLight,
          backgroundEnd: AppColors.readerLightDeep,
          text: AppColors.readerLightInk,
          secondaryText: AppColors.textSecondary,
          accent: AppColors.readerLightAccent,
          rule: AppColors.borderStrong,
          manuscript: false,
        );
    }
  }

  final ReaderThemeMode mode;
  final Brightness brightness;
  final Color background;
  final Color backgroundEnd;
  final Color text;
  final Color secondaryText;
  final Color accent;
  final Color rule;

  /// Parchment grain and the ornate double-ruled frame (Olaichuvadi only).
  final bool manuscript;

  static final ThemeData _lightBase = AppTheme.light();
  static final ThemeData _darkBase = AppTheme.dark();

  /// Theme for widgets drawn on the page (loaders, empty states, buttons).
  ThemeData theme() {
    final ThemeData base =
        brightness == Brightness.dark ? _darkBase : _lightBase;
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        onSurface: text,
        outline: rule,
      ),
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
      iconTheme: base.iconTheme.copyWith(color: text),
      progressIndicatorTheme: base.progressIndicatorTheme.copyWith(
        color: accent,
        circularTrackColor: rule.withOpacity(0.25),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: MaterialStatePropertyAll<Color>(rule.withOpacity(0.45)),
        thickness: const MaterialStatePropertyAll<double>(3),
        radius: const Radius.circular(3),
      ),
    );
  }

  ReadingStyle readingStyle(ReaderPreferences prefs) {
    return ReadingStyle(
      fontSize: prefs.fontSize,
      lineHeight: prefs.lineHeight.factor,
      textColor: text,
      secondaryColor: secondaryText,
      accentColor: accent,
      fontFamily: AppTypography.serifFamily,
      fontFamilyFallback: AppTypography.serifFallbacks,
      boldWeight: FontWeight.w600,
    );
  }
}
