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
    final Widget fallback = _CoverFallback(title: book.title, showTitle: showTitle);

    Widget child;
    final String? url = book.coverImage;
    if (url == null || url.isEmpty) {
      child = fallback;
    } else {
      child = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
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

class _CoverFallback extends StatelessWidget {
  const _CoverFallback({required this.title, required this.showTitle});

  final String title;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.featuredStart,
            AppColors.featuredEnd,
          ],
        ),
      ),
      child: showTitle
          ? Padding(
              padding: AppInsets.md,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bookTitle(
                    context,
                    fontSize: 16,
                    color: AppColors.neutral0,
                  ),
                ),
              ),
            )
          : const SizedBox.expand(),
    );
  }
}
