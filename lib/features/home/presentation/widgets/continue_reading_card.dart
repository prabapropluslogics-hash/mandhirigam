import 'package:flutter/material.dart';

import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/widgets/book_cover.dart';

class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({
    super.key,
    required this.book,
    this.onTap,
  });

  final Book book;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: AppInsets.pageHorizontal,
      child: Material(
        color: AppColors.surfaceMutedFor(Theme.of(context).brightness),
        borderRadius: AppRadii.cardBorder,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.cardBorder,
          child: Padding(
            padding: AppInsets.md,
            child: Row(
              children: [
                BookCover(
                  book: book,
                  width: AppSizes.bookCoverWidthSm,
                  height: AppSizes.bookCoverHeightSm,
                  showTitle: true,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'CONTINUE READING',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.primary,
                              letterSpacing: 0.8,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bookTitle(context, fontSize: 16),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Chapter ${book.currentChapter} of ${book.totalChapters}',
                        style: AppTypography.helper(context),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.full),
                        child: LinearProgressIndicator(
                          value: book.progress,
                          minHeight: AppSizes.progressHeight,
                          backgroundColor: AppColors.surfaceElevatedDark,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  AppIcons.chevronRight,
                  color: AppColors.textSecondaryFor(
                    Theme.of(context).brightness,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
