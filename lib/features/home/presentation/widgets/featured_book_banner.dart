import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/catalog_book.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/widgets/access_badge.dart';
import '../../../../shared/widgets/network_book_cover.dart';
import '../../../../state/library_controller.dart';

class FeaturedBookBanner extends StatelessWidget {
  const FeaturedBookBanner({
    super.key,
    required this.book,
    this.onTap,
  });

  final CatalogBook book;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool owned = context.watch<LibraryController>().owns(book.id);
    return Padding(
      padding: AppInsets.pageHorizontal,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.cardBorder,
          child: Ink(
            height: AppSizes.featuredCardHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: AppRadii.cardBorder,
            ),
            child: Padding(
              padding: AppInsets.md,
              child: Row(
                children: [
                  NetworkBookCover(
                    book: book,
                    width: 108,
                    height: 160,
                    showTitle: book.coverImage == null,
                  ),
                  const AppGap.md(axis: AppGapAxis.horizontal),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AccessBadge(book: book, owned: owned, compact: true),
                        const Spacer(),
                        Text(
                          book.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bookTitle(context, fontSize: 22),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${book.author} · ${book.languageLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.helper(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
