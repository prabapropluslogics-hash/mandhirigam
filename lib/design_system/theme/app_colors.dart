import 'package:flutter/material.dart';

/// Central color tokens for Maanthirigam.
///
/// ## Provisional notice
/// Brand and neutral hex values below are **provisional placeholders**.
/// They exist so ThemeData and components can compile and stay consistent.
/// Replace them in one place after UI screenshots/design tokens are finalized.
///
/// Screens and feature widgets must use these tokens (or [ThemeData]/
/// [ColorScheme]) — never scatter raw `Color(0x...)` values.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Brand (PROVISIONAL — swap after design review)
  // ---------------------------------------------------------------------------
  static const Color brandPrimary = Color(0xFF0F4C5C);
  static const Color brandSecondary = Color(0xFF5C8A6A);
  static const Color brandAccent = Color(0xFFC45C26);

  // ---------------------------------------------------------------------------
  // Neutrals (PROVISIONAL scale)
  // ---------------------------------------------------------------------------
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF7F8F8);
  static const Color neutral100 = Color(0xFFEEF1F1);
  static const Color neutral200 = Color(0xFFD8DEDE);
  static const Color neutral300 = Color(0xFFB5BFBF);
  static const Color neutral400 = Color(0xFF879494);
  static const Color neutral500 = Color(0xFF5F6C6C);
  static const Color neutral600 = Color(0xFF465151);
  static const Color neutral700 = Color(0xFF343C3C);
  static const Color neutral800 = Color(0xFF232929);
  static const Color neutral900 = Color(0xFF141818);

  // ---------------------------------------------------------------------------
  // Semantic — status
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF2F7D4A);
  static const Color onSuccess = neutral0;
  static const Color warning = Color(0xFFB54708);
  static const Color onWarning = neutral0;
  static const Color error = Color(0xFFB42318);
  static const Color onError = neutral0;
  static const Color info = Color(0xFF175CD3);
  static const Color onInfo = neutral0;

  // ---------------------------------------------------------------------------
  // Semantic — surfaces & backgrounds (light defaults; dark via ThemeData)
  // ---------------------------------------------------------------------------
  static const Color background = neutral50;
  static const Color backgroundDark = neutral900;
  static const Color surface = neutral0;
  static const Color surfaceDark = neutral800;
  static const Color surfaceMuted = neutral100;
  static const Color surfaceMutedDark = neutral700;

  /// Alias kept for existing theme references.
  static const Color scaffoldLight = background;
  static const Color scaffoldDark = backgroundDark;
  static const Color surfaceLight = surface;

  // ---------------------------------------------------------------------------
  // Semantic — text
  // ---------------------------------------------------------------------------
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral500;
  static const Color textTertiary = neutral400;
  static const Color textDisabled = neutral300;
  static const Color textOnBrand = neutral0;
  static const Color textPrimaryDark = neutral50;
  static const Color textSecondaryDark = neutral300;
  static const Color textDisabledDark = neutral600;

  /// Legacy aliases used by earlier foundation files.
  static const Color textPrimaryLight = textPrimary;
  static const Color textSecondaryLight = textSecondary;

  // ---------------------------------------------------------------------------
  // Semantic — borders, dividers, overlays, disabled
  // ---------------------------------------------------------------------------
  static const Color border = neutral200;
  static const Color borderStrong = neutral300;
  static const Color borderDark = neutral600;
  static const Color divider = neutral100;
  static const Color dividerDark = neutral700;

  static const Color disabled = neutral200;
  static const Color disabledDark = neutral700;
  static const Color onDisabled = neutral400;
  static const Color onDisabledDark = neutral500;

  static const Color overlay = Color(0x66000000);
  static const Color shadow = Color(0xFF000000);

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  static Color shadowWithOpacity(double opacity) =>
      shadow.withValues(alpha: opacity);

  static Color textPrimaryFor(Brightness brightness) =>
      brightness == Brightness.light ? textPrimary : textPrimaryDark;

  static Color textSecondaryFor(Brightness brightness) =>
      brightness == Brightness.light ? textSecondary : textSecondaryDark;

  static Color borderFor(Brightness brightness) =>
      brightness == Brightness.light ? border : borderDark;

  static Color dividerFor(Brightness brightness) =>
      brightness == Brightness.light ? divider : dividerDark;

  static Color backgroundFor(Brightness brightness) =>
      brightness == Brightness.light ? background : backgroundDark;

  static Color surfaceFor(Brightness brightness) =>
      brightness == Brightness.light ? surface : surfaceDark;
}
