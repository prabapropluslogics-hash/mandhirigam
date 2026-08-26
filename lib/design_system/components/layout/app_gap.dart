import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

enum AppGapAxis { vertical, horizontal }

/// Consistent gaps using design-system spacing tokens.
class AppGap extends StatelessWidget {
  const AppGap(
    this.size, {
    super.key,
    this.axis = AppGapAxis.vertical,
  });

  const AppGap.xxs({super.key, this.axis = AppGapAxis.vertical})
      : size = AppSpacing.xxs;
  const AppGap.xs({super.key, this.axis = AppGapAxis.vertical})
      : size = AppSpacing.xs;
  const AppGap.sm({super.key, this.axis = AppGapAxis.vertical})
      : size = AppSpacing.sm;
  const AppGap.md({super.key, this.axis = AppGapAxis.vertical})
      : size = AppSpacing.md;
  const AppGap.lg({super.key, this.axis = AppGapAxis.vertical})
      : size = AppSpacing.lg;
  const AppGap.xl({super.key, this.axis = AppGapAxis.vertical})
      : size = AppSpacing.xl;
  const AppGap.xxl({super.key, this.axis = AppGapAxis.vertical})
      : size = AppSpacing.xxl;
  const AppGap.xxxl({super.key, this.axis = AppGapAxis.vertical})
      : size = AppSpacing.xxxl;

  final double size;
  final AppGapAxis axis;

  @override
  Widget build(BuildContext context) {
    return switch (axis) {
      AppGapAxis.vertical => SizedBox(height: size),
      AppGapAxis.horizontal => SizedBox(width: size),
    };
  }
}
