import 'package:flutter/material.dart';

import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/widgets/book_cover.dart';

class DownloadedCoversRow extends StatelessWidget {
  const DownloadedCoversRow({
    super.key,
    required this.books,
    required this.onBookTap,
  });

  final List<Book> books;
  final ValueChanged<Book> onBookTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.bookCoverHeightDownloaded + AppSpacing.sm,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppInsets.pageHorizontal,
        itemCount: books.length,
        separatorBuilder: (_, _) =>
            const AppGap.md(axis: AppGapAxis.horizontal),
        itemBuilder: (BuildContext context, int index) {
          final Book book = books[index];
          return GestureDetector(
            onTap: () => onBookTap(book),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                BookCover(
                  book: book,
                  width: AppSizes.bookCoverWidthDownloaded,
                  height: AppSizes.bookCoverHeightDownloaded,
                  showTitle: true,
                ),
                const Positioned(
                  top: -AppSpacing.xs,
                  right: -AppSpacing.xs,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.xxs),
                      child: Icon(
                        AppIcons.checkPlain,
                        size: AppSizes.iconXs,
                        color: AppColors.neutral0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
