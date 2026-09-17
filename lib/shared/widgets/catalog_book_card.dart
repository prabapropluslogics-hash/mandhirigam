import 'package:flutter/material.dart';

import '../../data/models/catalog_book.dart';
import '../../design_system/components/layout/app_gap.dart';
import '../../design_system/theme/app_radii.dart';
import '../../design_system/theme/app_sizes.dart';
import '../../design_system/theme/app_spacing.dart';
import '../../design_system/theme/app_typography.dart';
import 'access_badge.dart';
import 'network_book_cover.dart';

class CatalogBookCard extends StatelessWidget {
  const CatalogBookCard({
    super.key,
    required this.book,
    this.owned = false,
    this.onTap,
  });

  final CatalogBook book;
  final bool owned;
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
            NetworkBookCover(
              book: book,
              width: AppSizes.bookCoverWidthSm,
              height: AppSizes.bookCoverHeightSm,
              showTitle: book.coverImage == null,
            ),
            const AppGap.md(axis: AppGapAxis.horizontal),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bookTitle(context, fontSize: 16),
                  ),
                  const AppGap.xs(),
                  Text(
                    '${book.author} · ${book.languageLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.helper(context),
                  ),
                  const AppGap.sm(),
                  AccessBadge(book: book, owned: owned, compact: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
