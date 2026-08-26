import 'package:flutter/material.dart';

import '../../theme/app_radii.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

/// Card surface that follows [CardTheme] from [AppTheme].
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.elevated = false,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool elevated;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final EdgeInsetsGeometry resolvedPadding = padding ?? AppInsets.lg;

    final Widget paddedChild = Padding(
      padding: resolvedPadding,
      child: child,
    );

    final Widget cardChild = onTap == null
        ? paddedChild
        : InkWell(
            onTap: onTap,
            borderRadius: AppRadii.cardBorder,
            child: paddedChild,
          );

    final Widget card = Card(
      margin: elevated ? EdgeInsets.zero : (margin ?? EdgeInsets.zero),
      clipBehavior: clipBehavior,
      child: cardChild,
    );

    if (!elevated) return card;

    return Container(
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: AppRadii.cardBorder,
        boxShadow: AppShadows.card,
      ),
      child: card,
    );
  }
}
