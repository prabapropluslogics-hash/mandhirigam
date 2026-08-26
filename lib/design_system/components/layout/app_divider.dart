import 'package:flutter/material.dart';

import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';

/// Thin divider using design-system thickness and theme color.
class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.space = AppSpacing.lg,
    this.thickness = AppSizes.dividerThickness,
    this.indent,
    this.endIndent,
    this.color,
  }) : _axis = Axis.horizontal;

  const AppDivider.vertical({
    super.key,
    this.space = AppSpacing.lg,
    this.thickness = AppSizes.dividerThickness,
    this.indent,
    this.endIndent,
    this.color,
  }) : _axis = Axis.vertical;

  /// Cross-axis space reserved by the divider (Divider.height / VerticalDivider.width).
  final double space;
  final double thickness;
  final double? indent;
  final double? endIndent;
  final Color? color;
  final Axis _axis;

  @override
  Widget build(BuildContext context) {
    if (_axis == Axis.vertical) {
      return VerticalDivider(
        width: space,
        thickness: thickness,
        indent: indent,
        endIndent: endIndent,
        color: color,
      );
    }

    return Divider(
      height: space,
      thickness: thickness,
      indent: indent,
      endIndent: endIndent,
      color: color,
    );
  }
}
