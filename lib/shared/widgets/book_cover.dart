import 'package:flutter/material.dart';

import '../../design_system/theme/app_colors.dart';
import '../../design_system/theme/app_radii.dart';
import '../../design_system/theme/app_spacing.dart';
import '../../design_system/theme/app_typography.dart';
import '../models/book.dart';

/// Local cover placeholder. Swap in [Book.coverAsset] when final art arrives.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.book,
    this.width,
    this.height,
    this.showTitle = false,
    this.borderRadius,
  });

  final Book book;
  final double? width;
  final double? height;
  final bool showTitle;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = borderRadius ?? AppRadii.coverBorder;
    final Widget painted = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[book.coverStart, book.coverEnd],
        ),
      ),
      child: showTitle
          ? Padding(
              padding: AppInsets.md,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  book.title,
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

    final Widget child = book.coverAsset == null
        ? painted
        : Image.asset(
            book.coverAsset!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => painted,
          );

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
