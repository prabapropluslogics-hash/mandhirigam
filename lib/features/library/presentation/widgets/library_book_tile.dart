import 'package:flutter/material.dart';

import '../../../../data/models/catalog_book.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/widgets/access_badge.dart';
import '../../../../shared/widgets/network_book_cover.dart';

/// Bookshelf tile: cover resting on a soft shelf shadow, then the owned
/// badge, serif title and a "author · language" line from real data.
class LibraryBookTile extends StatelessWidget {
  const LibraryBookTile({
    super.key,
    required this.book,
    required this.width,
    required this.onTap,
  });

  static const double coverAspect = 1.48;

  static const double _titleSize = 15;
  static const double _titleLineHeight = 1.3;
  static const double _metaSize = 12;
  static const double _metaLineHeight = 1.4;
  static const double _badgeTextSize = 11;

  final CatalogBook book;
  final double width;
  final VoidCallback onTap;

  /// Height a grid cell needs for a tile of [width] at the current text scale.
  static double heightFor(BuildContext context, double width) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    return width * coverAspect +
        AppSpacing.md +
        scaler.scale(_badgeTextSize) * 1.3 +
        AppSpacing.xs +
        AppSpacing.sm +
        scaler.scale(_titleSize) * _titleLineHeight * 2 +
        AppSpacing.xxs +
        scaler.scale(_metaSize) * _metaLineHeight +
        AppSpacing.sm;
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadii.sm);
    final String meta = <String>[book.author.trim(), book.languageLabel.trim()]
        .where((String part) => part.isNotEmpty)
        .join(' · ');

    return Semantics(
      button: true,
      child: GestureDetector(
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
                      color: AppColors.shadowWithOpacity(0.6),
                      blurRadius: 16,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: AppColors.brandPrimary.withOpacity(0.07),
                      blurRadius: 22,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    NetworkBookCover(
                      book: book,
                      width: width,
                      height: width * coverAspect,
                      showTitle: book.coverImage == null,
                      borderRadius: radius,
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: radius,
                            border: Border.all(
                              color: AppColors.brandPrimary.withOpacity(0.16),
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
              AccessBadge(book: book, owned: true, compact: true),
              const SizedBox(height: AppSpacing.sm),
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bookTitle(
                  context,
                  fontSize: _titleSize,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimaryDark,
                ).copyWith(height: _titleLineHeight),
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(context).copyWith(
                    fontSize: _metaSize,
                    height: _metaLineHeight,
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
