import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../design_system/theme/app_colors.dart';
import '../../design_system/theme/app_radii.dart';
import '../../design_system/theme/app_spacing.dart';
import '../../design_system/theme/app_typography.dart';
import '../../data/models/catalog_book.dart';

class NetworkBookCover extends StatelessWidget {
  const NetworkBookCover({
    super.key,
    required this.book,
    this.width,
    this.height,
    this.showTitle = false,
    this.borderRadius,
  });

  final CatalogBook book;
  final double? width;
  final double? height;
  final bool showTitle;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = borderRadius ?? AppRadii.coverBorder;
    final Widget fallback =
        _CoverFallback(title: book.title, showTitle: showTitle);

    Widget child;
    final String? url = book.coverImage;
    if (url == null || url.isEmpty) {
      child = fallback;
    } else {
      final double? width = this.width;
      // Decode at display size; the disk cache still keeps the original.
      final int? memCacheWidth = width == null
          ? null
          : (width * (MediaQuery.maybeDevicePixelRatioOf(context) ?? 2))
              .round();
      child = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: memCacheWidth,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      );
    }

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: radius,
        child: child,
      ),
    );
  }
}

/// Cloth-bound look for books without a cover: dark warm board, a spine,
/// a faint gold inset frame and (optionally) the title set in serif.
class _CoverFallback extends StatelessWidget {
  const _CoverFallback({required this.title, required this.showTitle});

  /// Below this width the frame and ornament are dropped.
  static const double _detailedMinWidth = 72;

  final String title;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 108;
        final bool detailed = width >= _detailedMinWidth;
        final double spine = math.max(3, width * 0.06);
        final double inset = math.max(4, width * 0.07);
        return Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    AppColors.featuredMid,
                    AppColors.featuredEnd,
                    AppColors.splashCharcoal,
                  ],
                  stops: <double>[0, 0.55, 1],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.2, -0.6),
                  radius: 0.9,
                  colors: <Color>[
                    AppColors.brandAccent.withOpacity(0.18),
                    AppColors.brandAccent.withOpacity(0),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: spine,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      AppColors.shadowWithOpacity(0.45),
                      AppColors.shadowWithOpacity(0.15),
                    ],
                  ),
                  border: Border(
                    right: BorderSide(
                      color: AppColors.brandPrimary.withOpacity(0.25),
                      width: 0.6,
                    ),
                  ),
                ),
              ),
            ),
            if (detailed)
              Positioned.fill(
                left: spine + inset * 0.6,
                top: inset,
                right: inset,
                bottom: inset,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.brandPrimary.withOpacity(0.3),
                      width: 0.7,
                    ),
                  ),
                ),
              ),
            if (showTitle)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  spine + inset + AppSpacing.xs,
                  inset + AppSpacing.sm,
                  inset + AppSpacing.xs,
                  inset + AppSpacing.sm,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (detailed) ...[
                      Transform.rotate(
                        angle: math.pi / 4,
                        child: SizedBox.square(
                          dimension: 4,
                          child: ColoredBox(
                            color: AppColors.brandAccent.withOpacity(0.8),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTypography.bookTitle(
                          context,
                          fontSize: (width / 8).clamp(11.0, 18.0),
                          fontWeight: FontWeight.w500,
                          color: AppColors.splashTagline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
