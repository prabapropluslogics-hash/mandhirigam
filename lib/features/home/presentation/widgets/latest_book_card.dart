import 'package:flutter/material.dart';

import '../../../../data/models/catalog_book.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/widgets/access_badge.dart';
import '../../../../shared/widgets/network_book_cover.dart';

/// Editorial book tile for Home rails: elevated cover, access badge, serif
/// title and author.
class LatestBookCard extends StatelessWidget {
  const LatestBookCard({
    super.key,
    required this.book,
    required this.owned,
    required this.width,
    required this.onTap,
  });

  /// Cover height as a multiple of its width (classic 2:3 book proportion).
  static const double coverAspect = 1.48;

  static const double _titleSize = 14;
  static const double _titleLineHeight = 1.25;
  static const double _authorSize = 12;
  static const double _authorLineHeight = 1.4;
  static const double _badgeTextSize = 11;

  final CatalogBook book;
  final bool owned;
  final double width;
  final VoidCallback onTap;

  /// Height a rail must give a card of [width] at the current text scale.
  static double heightFor(BuildContext context, double width) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double badge = scaler.scale(_badgeTextSize) * 1.3 + AppSpacing.xs;
    final double title = scaler.scale(_titleSize) * _titleLineHeight * 2;
    final double author = scaler.scale(_authorSize) * _authorLineHeight;
    return width * coverAspect +
        AppSpacing.md +
        badge +
        AppSpacing.sm +
        title +
        AppSpacing.xxs +
        author +
        AppSpacing.sm;
  }

  @override
  Widget build(BuildContext context) {
    final double coverHeight = width * coverAspect;
    final BorderRadius radius = BorderRadius.circular(AppRadii.sm);
    final String author = book.author.trim();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowWithOpacity(0.55),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: AppColors.brandPrimary.withOpacity(0.06),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  NetworkBookCover(
                    book: book,
                    width: width,
                    height: coverHeight,
                    showTitle: book.coverImage == null,
                    borderRadius: radius,
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          border: Border.all(
                            color: AppColors.splashTagline.withOpacity(0.08),
                            width: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AccessBadge(book: book, owned: owned, compact: true),
            const SizedBox(height: AppSpacing.sm),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bookTitle(
                context,
                fontSize: _titleSize,
                color: AppColors.textPrimaryDark,
              ).copyWith(height: _titleLineHeight),
            ),
            if (author.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption(context).copyWith(
                  fontSize: _authorSize,
                  height: _authorLineHeight,
                  color: AppColors.textSecondaryDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
