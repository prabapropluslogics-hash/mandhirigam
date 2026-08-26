import 'package:flutter/painting.dart';

/// Spacing scale (logical pixels).
///
/// Prefer these tokens (and [AppInsets]) over hardcoded paddings/margins.
abstract final class AppSpacing {
  static const double none = 0;
  static const double xxs = 2;

  /// Extra small
  static const double xs = 4;

  /// Small
  static const double sm = 8;

  /// Medium
  static const double md = 12;

  /// Large
  static const double lg = 16;

  /// Extra large
  static const double xl = 20;

  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;

  /// Aliases matching common design-spec naming.
  static const double extraSmall = xs;
  static const double small = sm;
  static const double medium = md;
  static const double large = lg;
  static const double extraLarge = xl;

  /// Default page insets for phone layouts.
  static const double pageHorizontal = lg;
  static const double pageVertical = lg;
}

/// Common [EdgeInsets] built from [AppSpacing] tokens.
abstract final class AppInsets {
  static const EdgeInsets zero = EdgeInsets.zero;

  static const EdgeInsets xs = EdgeInsets.all(AppSpacing.xs);
  static const EdgeInsets sm = EdgeInsets.all(AppSpacing.sm);
  static const EdgeInsets md = EdgeInsets.all(AppSpacing.md);
  static const EdgeInsets lg = EdgeInsets.all(AppSpacing.lg);
  static const EdgeInsets xl = EdgeInsets.all(AppSpacing.xl);
  static const EdgeInsets xxl = EdgeInsets.all(AppSpacing.xxl);

  static const EdgeInsets page = EdgeInsets.symmetric(
    horizontal: AppSpacing.pageHorizontal,
    vertical: AppSpacing.pageVertical,
  );

  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(
    horizontal: AppSpacing.pageHorizontal,
  );

  static const EdgeInsets buttonHorizontal = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
  );

  static const EdgeInsets inputContent = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  );

  static const EdgeInsets textButton = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.sm,
  );

  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.only(left: left, top: top, right: right, bottom: bottom);
  }

  static EdgeInsets symmetric({double horizontal = 0, double vertical = 0}) {
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }
}
