import 'package:flutter/material.dart';

import '../../../../design_system/components/feedback/access_badge.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/widgets/book_cover.dart';

class LibraryBookItem extends StatelessWidget {
  const LibraryBookItem({
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bookTitle(context, fontSize: 16),
                        ),
                      ),
                      const AppGap.sm(axis: AppGapAxis.horizontal),
                      AccessBadge(
                        kind: book.isPremium
                            ? AccessKind.premium
                            : AccessKind.free,
                        variant: AccessBadgeVariant.outline,
                        compact: true,
                      ),
                    ],
                  ),
                  const AppGap.xs(),
                  Text(
                    book.currentChapter > 0
                        ? book.chapterProgressLabel
                        : book.author,
                    style: AppTypography.helper(context),
                  ),
                  if (book.currentChapter > 0) ...[
                    const AppGap.sm(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadii.full),
                      child: LinearProgressIndicator(
                        value: book.progress,
                        minHeight: AppSizes.progressHeight,
                        backgroundColor: AppColors.surfaceElevatedDark,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
