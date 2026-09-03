import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_gradients.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_typography.dart';

/// Circular avatar with an initial and optional brand gradient fallback.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.initial,
    this.size = AppSizes.avatar,
    this.useGradient = false,
    this.backgroundColor,
    this.semanticLabel,
  });

  final String initial;
  final double size;
  final bool useGradient;
  final Color? backgroundColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final double fontSize = size >= AppSizes.avatarLg ? 28 : 16;

    return Semantics(
      label: semanticLabel ?? initial,
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: useGradient
                ? null
                : (backgroundColor ?? AppColors.avatarFallback),
            gradient: useGradient ? AppGradients.avatar : null,
          ),
          child: Center(
            child: Text(
              initial,
              style: AppTypography.bookTitle(
                context,
                fontSize: fontSize,
                color: AppColors.neutral0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
