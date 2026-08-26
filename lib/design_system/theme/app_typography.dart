import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography system for Maanthirigam.
///
/// ## Provisional notice
/// Font family and sizes are provisional until brand type specs arrive.
/// Set [fontFamily] when font files are registered in `pubspec.yaml`.
///
/// Prefer named helpers ([pageTitle], [body], [button], …) or
/// [ThemeData.textTheme] — do not invent ad-hoc [TextStyle]s in screens.
abstract final class AppTypography {
  /// PROVISIONAL — replace with brand font family name when assets are added.
  static const String? fontFamily = null;

  // ---------------------------------------------------------------------------
  // Named roles (use these from screens / components)
  // ---------------------------------------------------------------------------

  static TextStyle display(BuildContext context) =>
      Theme.of(context).textTheme.displaySmall!;

  static TextStyle pageTitle(BuildContext context) =>
      Theme.of(context).textTheme.headlineMedium!;

  static TextStyle sectionTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!;

  static TextStyle body(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!;

  static TextStyle bodySmall(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!;

  static TextStyle label(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge!;

  static TextStyle button(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge!;

  static TextStyle caption(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!;

  static TextStyle helper(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: AppColors.textSecondaryFor(brightness),
        );
  }

  static TextStyle error(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: Theme.of(context).colorScheme.error,
        );
  }

  // ---------------------------------------------------------------------------
  // Material TextTheme builder (wired into AppTheme)
  // ---------------------------------------------------------------------------

  static TextTheme textTheme({required Brightness brightness}) {
    final Color primary = AppColors.textPrimaryFor(brightness);
    final Color secondary = AppColors.textSecondaryFor(brightness);

    TextStyle base(double size, FontWeight weight, {double height = 1.25}) {
      return TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: primary,
        letterSpacing: 0,
      );
    }

    return TextTheme(
      // Display / large headings
      displayLarge: base(40, FontWeight.w700, height: 1.15),
      displayMedium: base(32, FontWeight.w700, height: 1.15),
      displaySmall: base(28, FontWeight.w700, height: 1.2),
      // Page titles
      headlineLarge: base(24, FontWeight.w600, height: 1.25),
      headlineMedium: base(20, FontWeight.w600, height: 1.25),
      headlineSmall: base(18, FontWeight.w600, height: 1.3),
      // Section titles
      titleLarge: base(18, FontWeight.w600),
      titleMedium: base(16, FontWeight.w600),
      titleSmall: base(14, FontWeight.w600),
      // Body
      bodyLarge: base(16, FontWeight.w400, height: 1.5),
      bodyMedium: base(14, FontWeight.w400, height: 1.5),
      // Small / caption / helper base
      bodySmall: base(12, FontWeight.w400, height: 1.4).copyWith(color: secondary),
      // Labels / buttons
      labelLarge: base(14, FontWeight.w600),
      labelMedium: base(12, FontWeight.w600),
      labelSmall: base(11, FontWeight.w600).copyWith(color: secondary),
    );
  }
}
