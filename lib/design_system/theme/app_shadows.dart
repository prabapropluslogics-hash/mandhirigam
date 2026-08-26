import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Elevation / shadow tokens for cards, sheets, and dialogs.
///
/// Shadow ink uses [AppColors.shadow] — no raw black hex in components.
abstract final class AppShadows {
  static const List<BoxShadow> none = <BoxShadow>[];

  static final List<BoxShadow> sm = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowWithOpacity(0.08),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static final List<BoxShadow> md = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowWithOpacity(0.10),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static final List<BoxShadow> lg = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowWithOpacity(0.14),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  /// Semantic aliases
  static List<BoxShadow> get card => sm;
  static List<BoxShadow> get elevated => md;
  static List<BoxShadow> get dialog => lg;

  static List<BoxShadow> softBrand = <BoxShadow>[
    BoxShadow(
      color: AppColors.brandPrimary.withValues(alpha: 0.18),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}
