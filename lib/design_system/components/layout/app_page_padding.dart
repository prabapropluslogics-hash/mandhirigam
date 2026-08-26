import 'package:flutter/material.dart';

import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';

/// Standard page padding with optional max-width centering for larger screens.
class AppPagePadding extends StatelessWidget {
  const AppPagePadding({
    super.key,
    required this.child,
    this.horizontal,
    this.vertical,
    this.constrainWidth = true,
  });

  final Widget child;
  final double? horizontal;
  final double? vertical;
  final bool constrainWidth;

  @override
  Widget build(BuildContext context) {
    final double resolvedHorizontal = horizontal ??
        Responsive.value(
          context,
          compact: AppSpacing.pageHorizontal,
          medium: AppSpacing.xxl,
          expanded: AppSpacing.xxxl,
        );
    final double resolvedVertical = vertical ?? AppSpacing.pageVertical;

    final Widget padded = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: resolvedHorizontal,
        vertical: resolvedVertical,
      ),
      child: child,
    );

    if (!constrainWidth) return padded;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
        child: padded,
      ),
    );
  }
}
