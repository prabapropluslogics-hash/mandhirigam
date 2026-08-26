import 'package:flutter/material.dart';

import '../../design_system/components/feedback/premium_badge.dart';
import '../../design_system/components/feedback/rating_view.dart';
import '../../design_system/components/layout/app_gap.dart';
import '../../design_system/theme/app_radii.dart';
import '../../design_system/theme/app_sizes.dart';
import '../../design_system/theme/app_spacing.dart';
import '../../design_system/theme/app_typography.dart';
import '../models/book.dart';
import 'book_cover.dart';

/// Horizontal book row used in search results and similar lists.
class BookListItem extends StatelessWidget {
  const BookListItem({
    super.key,
    required this.book,
    this.onTap,
  });

  final Book book;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.cardBorder,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            BookCover(
              book: book,
              width: AppSizes.bookCoverWidthSm,
              height: AppSizes.bookCoverHeightSm,
              showTitle: true,
            ),
            const AppGap.md(axis: AppGapAxis.horizontal),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bookTitle(context, fontSize: 16),
                  ),
                  const AppGap.xs(),
                  Text(
                    '${book.author} · ${book.genre}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.helper(context),
                  ),
                  const AppGap.sm(),
                  Row(
                    children: [
                      RatingView(rating: book.rating, compact: true),
                      if (book.isPremium) ...[
                        const AppGap.sm(axis: AppGapAxis.horizontal),
                        const PremiumBadge(compact: true),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
