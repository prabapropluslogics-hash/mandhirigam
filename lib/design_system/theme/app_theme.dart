import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_sizes.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds light/dark [ThemeData] from design tokens.
///
/// All component themes reference [AppColors], [AppRadii], [AppSizes],
/// [AppSpacing], and [AppTypography] — never local magic numbers.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;

    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.brandPrimary,
      onPrimary: AppColors.textOnBrand,
      secondary: AppColors.brandSecondary,
      onSecondary: AppColors.textOnBrand,
      tertiary: AppColors.brandAccent,
      onTertiary: AppColors.textOnBrand,
      error: AppColors.error,
      onError: AppColors.onError,
      surface: AppColors.surfaceFor(brightness),
      onSurface: AppColors.textPrimaryFor(brightness),
      surfaceContainerHighest:
          isLight ? AppColors.surfaceMuted : AppColors.surfaceMutedDark,
      outline: AppColors.borderFor(brightness),
      outlineVariant: AppColors.dividerFor(brightness),
    );

    final TextTheme textTheme = AppTypography.textTheme(brightness: brightness);
    final Color disabledBackground =
        isLight ? AppColors.disabled : AppColors.disabledDark;
    final Color disabledForeground =
        isLight ? AppColors.onDisabled : AppColors.onDisabledDark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundFor(brightness),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      disabledColor: disabledForeground,
      dividerColor: AppColors.dividerFor(brightness),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.backgroundFor(brightness),
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
        toolbarHeight: AppSizes.appBarHeight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeightMd),
          elevation: 0,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: disabledBackground,
          disabledForegroundColor: disabledForeground,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.buttonBorder),
          textStyle: textTheme.labelLarge,
          padding: AppInsets.buttonHorizontal,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeightMd),
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: disabledForeground,
          side: BorderSide(
            color: colorScheme.outline,
            width: AppSizes.borderThin,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.buttonBorder),
          textStyle: textTheme.labelLarge,
          padding: AppInsets.buttonHorizontal,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          disabledForegroundColor: disabledForeground,
          textStyle: textTheme.labelLarge,
          padding: AppInsets.textButton,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          disabledForegroundColor: disabledForeground,
          minimumSize: const Size(
            AppSizes.iconButtonTapTarget,
            AppSizes.iconButtonTapTarget,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceFor(brightness),
        contentPadding: AppInsets.inputContent,
        border: OutlineInputBorder(
          borderRadius: AppRadii.textFieldBorder,
          borderSide: BorderSide(
            color: colorScheme.outline,
            width: AppSizes.borderThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.textFieldBorder,
          borderSide: BorderSide(
            color: colorScheme.outline,
            width: AppSizes.borderThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.textFieldBorder,
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: AppSizes.borderMedium,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.textFieldBorder,
          borderSide: BorderSide(
            color: colorScheme.error,
            width: AppSizes.borderThin,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.textFieldBorder,
          borderSide: BorderSide(
            color: colorScheme.error,
            width: AppSizes.borderMedium,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.textFieldBorder,
          borderSide: BorderSide(
            color: disabledBackground,
            width: AppSizes.borderThin,
          ),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondaryFor(brightness),
        ),
        labelStyle: textTheme.bodyMedium,
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondaryFor(brightness),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.cardBorder,
          side: BorderSide(
            color: colorScheme.outlineVariant,
            width: AppSizes.borderThin,
          ),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.dialogBorder),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
        insetPadding: AppInsets.lg,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: AppSizes.dividerThickness,
        space: AppSizes.dividerThickness,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.buttonBorder),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colorScheme.outlineVariant,
      ),
    );
  }
}
