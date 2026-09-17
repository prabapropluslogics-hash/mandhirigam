import 'package:flutter/material.dart';

import '../../core/app_container.dart';
import 'app_colors.dart';
import 'app_radii.dart';
import 'app_sizes.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds light/dark [ThemeData] from design tokens.
abstract final class AppTheme {
  static ThemeData light({BrandingColors? branding}) =>
      _build(Brightness.light, branding);

  static ThemeData dark({BrandingColors? branding}) =>
      _build(Brightness.dark, branding);

  static ThemeData _build(Brightness brightness, BrandingColors? branding) {
    final bool isLight = brightness == Brightness.light;
    final Color primary = branding?.primary ?? AppColors.brandPrimary;
    final Color secondary = branding?.secondary ?? AppColors.brandSecondary;
    final Color button = branding?.button ?? AppColors.brandPrimary;
    final Color onPrimary = branding?.onPrimary ?? AppColors.textOnBrand;
    final Color onButton = branding?.onButton ?? AppColors.textOnBrand;

    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: secondary.computeLuminance() > 0.55
          ? AppColors.textOnBrand
          : AppColors.neutral0,
      tertiary: AppColors.brandAccent,
      onTertiary: AppColors.textOnBrand,
      error: AppColors.error,
      onError: AppColors.onError,
      surface: AppColors.surfaceFor(brightness),
      background: AppColors.backgroundFor(brightness),
      onBackground: AppColors.background,
      onSurface: AppColors.textPrimaryFor(brightness),
      // surfaceContainerHighest: AppColors.surfaceMutedFor(brightness),
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
      splashFactory: NoSplash.splashFactory,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      disabledColor: disabledForeground,
      dividerColor: AppColors.dividerFor(brightness),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.backgroundFor(brightness),
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
        toolbarHeight: AppSizes.appBarHeight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeightMd),
          elevation: 0,
          backgroundColor: button,
          foregroundColor: onButton,
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
          foregroundColor: colorScheme.onSurface,
          disabledForegroundColor: disabledForeground,
          backgroundColor: AppColors.surfaceMutedFor(brightness),
          side: BorderSide.none,
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
        fillColor: AppColors.surfaceMutedFor(brightness),
        contentPadding: AppInsets.inputContent,
        border: OutlineInputBorder(
          borderRadius: AppRadii.searchBarBorder,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.searchBarBorder,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.searchBarBorder,
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: AppSizes.borderMedium,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.searchBarBorder,
          borderSide: BorderSide(
            color: colorScheme.error,
            width: AppSizes.borderThin,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.searchBarBorder,
          borderSide: BorderSide(
            color: colorScheme.error,
            width: AppSizes.borderMedium,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.searchBarBorder,
          borderSide: BorderSide.none,
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
      cardTheme: CardTheme(
        elevation: 0,
        color: AppColors.surfaceMutedFor(brightness),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.cardBorder),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.dialogBorder),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surfaceFor(brightness),
        modalBackgroundColor: AppColors.surfaceFor(brightness),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.bottomSheet),
          ),
        ),
        dragHandleColor: AppColors.neutral600,
        showDragHandle: false,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: AppColors.surfaceElevatedDark,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withOpacity(0.16),
        trackHeight: AppSizes.progressHeight,
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
        linearTrackColor: AppColors.surfaceElevatedDark,
      ),
    );
  }
}
