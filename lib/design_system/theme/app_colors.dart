import 'package:flutter/material.dart';

/// Central color tokens for Maanthirigam.
///
/// Values are taken from the product UI reference (dark charcoal + gold).
/// Screens must use these tokens — never scatter raw `Color(0x...)` values.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Brand — gold / bronze from the UI reference
  // ---------------------------------------------------------------------------
  static const Color brandPrimary = Color(0xFFC9A36A);
  static const Color brandSecondary = Color(0xFFB08D57);
  static const Color brandAccent = Color(0xFFE1C48A);

  // ---------------------------------------------------------------------------
  // Neutrals — charcoal scale from the UI reference
  // ---------------------------------------------------------------------------
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF4F1EA);
  static const Color neutral100 = Color(0xFFE8E2D6);
  static const Color neutral200 = Color(0xFFC9C2B5);
  static const Color neutral300 = Color(0xFF9A9388);
  static const Color neutral400 = Color(0xFF7A746B);
  static const Color neutral500 = Color(0xFF8A8680);
  static const Color neutral600 = Color(0xFF3A3A3A);
  static const Color neutral700 = Color(0xFF2A2A2A);
  static const Color neutral800 = Color(0xFF1A1A1A);
  static const Color neutral900 = Color(0xFF0D0D0D);

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
  // Semantic — surfaces & backgrounds
  // ---------------------------------------------------------------------------
  static const Color background = Color(0xFFF4F1EA);
  static const Color backgroundDark = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1A1A);
  static const Color surfaceMuted = Color(0xFFEDE8DE);
  static const Color surfaceMutedDark = Color(0xFF242424);
  static const Color surfaceElevatedDark = Color(0xFF2C2C2C);

  static const Color scaffoldLight = background;
  static const Color scaffoldDark = backgroundDark;
  static const Color surfaceLight = surface;

  static const Color featuredStart = Color(0xFFD4B07A);
  static const Color featuredMid = Color(0xFF8A5A32);
  static const Color featuredEnd = Color(0xFF2B1A10);

  static const Color avatarFallback = Color(0xFF6E5A9E);

  // ---------------------------------------------------------------------------
  // Semantic — text
  // ---------------------------------------------------------------------------
  static const Color textPrimary = Color(0xFF141414);
  static const Color textSecondary = Color(0xFF6F6A63);
  static const Color textTertiary = Color(0xFF8A8680);
  static const Color textDisabled = Color(0xFFB5AFA6);
  static const Color textOnBrand = Color(0xFF1A140C);
  static const Color textPrimaryDark = Color(0xFFF6F4F0);
  static const Color textSecondaryDark = Color(0xFFA8A49E);
  static const Color textDisabledDark = Color(0xFF6A6660);

  static const Color textPrimaryLight = textPrimary;
  static const Color textSecondaryLight = textSecondary;

  // ---------------------------------------------------------------------------
  // Semantic — borders, dividers, overlays, disabled
  // ---------------------------------------------------------------------------
  static const Color border = Color(0xFFD8D2C8);
  static const Color borderStrong = Color(0xFFC0B8AC);
  static const Color borderDark = Color(0xFF333333);
  static const Color divider = Color(0xFFE8E2D6);
  static const Color dividerDark = Color(0xFF2A2A2A);

  static const Color disabled = Color(0xFFD8D2C8);
  static const Color disabledDark = Color(0xFF3A3A3A);
  static const Color onDisabled = Color(0xFF8A8680);
  static const Color onDisabledDark = Color(0xFF7A746B);

  static const Color overlay = Color(0x99000000);
  static const Color shadow = Color(0xFF000000);

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  static Color shadowWithOpacity(double opacity) =>
      shadow.withOpacity(opacity);

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

  static Color surfaceMutedFor(Brightness brightness) =>
      brightness == Brightness.light ? surfaceMuted : surfaceMutedDark;
}
