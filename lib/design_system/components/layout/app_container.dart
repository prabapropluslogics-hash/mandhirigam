import 'package:flutter/material.dart';

import '../../theme/app_radii.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';

/// Surface container with optional border, radius, padding, and shadow.
///
/// Use for generic elevated/padded regions. Prefer [AppCard] for card UI.
class AppContainer extends StatelessWidget {
  const AppContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.color,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.shadows,
    this.clipBehavior = Clip.none,
    this.alignment,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? color;
  final Color? borderColor;
  final double? borderWidth;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;
  final Clip clipBehavior;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final BorderRadius radius = borderRadius ?? AppRadii.containerBorder;
    final bool showBorder = borderColor != null || borderWidth != null;

    return Container(
      width: width,
      height: height,
      margin: margin,
      alignment: alignment,
      padding: padding ?? AppInsets.md,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        borderRadius: radius,
        border: showBorder
            ? Border.all(
                color: borderColor ?? colors.outline,
                width: borderWidth ?? AppSizes.borderThin,
              )
            : null,
        boxShadow: shadows,
      ),
      child: child,
    );
  }
}
