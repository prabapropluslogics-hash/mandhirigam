import 'package:flutter/material.dart';

import '../../../../data/models/catalog_book.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/buttons/app_button_shared.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/widgets/network_book_cover.dart';

/// A genuine reading position for one book. Build it only from a real
/// progress source; [chapterLabel] and [progress] are shown only when known.
@immutable
class ContinueReadingEntry {
  const ContinueReadingEntry({
    required this.book,
    required this.chapterId,
    this.chapterLabel,
    this.progress,
  });

  final CatalogBook book;
  final String chapterId;
  final String? chapterLabel;

  /// Fraction read, `0..1`.
  final double? progress;
}

/// Compact Home card for resuming a book.
class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({
    super.key,
    required this.entry,
    required this.onContinue,
  });

  final ContinueReadingEntry entry;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final CatalogBook book = entry.book;
    final String? chapter = entry.chapterLabel?.trim();
    final double? progress = entry.progress?.clamp(0.0, 1.0);

    return Padding(
      padding: AppInsets.pageHorizontal,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withOpacity(0.85),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(
            color: AppColors.brandPrimary.withOpacity(0.16),
            width: AppSizes.borderThin,
          ),
        ),
        child: Padding(
          padding: AppInsets.md,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NetworkBookCover(
                book: book,
                width: AppSizes.bookCoverWidthSm,
                height: AppSizes.bookCoverHeightSm,
                showTitle: book.coverImage == null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bookTitle(
                        context,
                        fontSize: 16,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                    if (chapter != null && chapter.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        chapter,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.helper(context),
                      ),
                    ],
                    if (progress != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadii.full),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: AppSizes.progressHeight,
                                backgroundColor: AppColors.surfaceElevatedDark,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${(progress * 100).round()}%',
                            style: AppTypography.caption(context),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: 'Continue Reading',
                      size: AppButtonSize.small,
                      isExpanded: false,
                      onPressed: onContinue,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
