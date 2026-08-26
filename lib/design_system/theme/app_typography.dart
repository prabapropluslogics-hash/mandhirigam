import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography system for Maanthirigam.
///
/// UI copy uses the platform sans family. Book titles use a serif stack
/// matching the reference (Georgia / Times).
abstract final class AppTypography {
  static const String? fontFamily = null;
  static const String serifFamily = 'Georgia';
  static const List<String> serifFallbacks = <String>[
    'Times New Roman',
    'Noto Serif',
    'serif',
  ];

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

  static TextStyle bookTitle(
    BuildContext context, {
    double fontSize = 22,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: serifFamily,
      fontFamilyFallback: serifFallbacks,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.2,
      color: color ?? AppColors.textPrimaryFor(Theme.of(context).brightness),
    );
  }

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
      displayLarge: base(40, FontWeight.w700, height: 1.15),
      displayMedium: base(32, FontWeight.w700, height: 1.15),
      displaySmall: base(28, FontWeight.w700, height: 1.2),
      headlineLarge: base(24, FontWeight.w600, height: 1.25),
      headlineMedium: base(22, FontWeight.w700, height: 1.2),
      headlineSmall: base(18, FontWeight.w600, height: 1.3),
      titleLarge: base(18, FontWeight.w600),
      titleMedium: base(16, FontWeight.w600),
      titleSmall: base(14, FontWeight.w600),
      bodyLarge: base(16, FontWeight.w400, height: 1.5),
      bodyMedium: base(14, FontWeight.w400, height: 1.5),
      bodySmall:
          base(12, FontWeight.w400, height: 1.4).copyWith(color: secondary),
      labelLarge: base(14, FontWeight.w600),
      labelMedium: base(12, FontWeight.w600),
      labelSmall: base(11, FontWeight.w600).copyWith(color: secondary),
    );
  }
}
