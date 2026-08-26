import 'package:flutter/widgets.dart';

/// Breakpoints and helpers for responsive layouts.
///
/// Prefer these over magic numbers when branching UI by viewport width.
abstract final class Breakpoints {
  static const double compact = 600;
  static const double medium = 840;
  static const double expanded = 1200;
}

enum AppWindowSize { compact, medium, expanded }

abstract final class Responsive {
  static AppWindowSize windowSizeOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= Breakpoints.expanded) return AppWindowSize.expanded;
    if (width >= Breakpoints.medium) return AppWindowSize.medium;
    return AppWindowSize.compact;
  }

  static bool isCompact(BuildContext context) =>
      windowSizeOf(context) == AppWindowSize.compact;

  static T value<T>(
    BuildContext context, {
    required T compact,
    T? medium,
    T? expanded,
  }) {
    return switch (windowSizeOf(context)) {
      AppWindowSize.expanded => expanded ?? medium ?? compact,
      AppWindowSize.medium => medium ?? compact,
      AppWindowSize.compact => compact,
    };
  }
}
