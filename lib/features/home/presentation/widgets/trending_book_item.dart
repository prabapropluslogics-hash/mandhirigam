import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/widgets/book_cover.dart';

class TrendingBookItem extends StatelessWidget {
  const TrendingBookItem({
    super.key,
    required this.book,
    this.onTap,
  });

  final Book book;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BookCover(
        book: book,
        width: AppSizes.bookCoverWidthMd,
        height: AppSizes.bookCoverHeightMd,
        showTitle: true,
      ),
    );
  }
}

class TrendingBooksRow extends StatelessWidget {
  const TrendingBooksRow({
    super.key,
    required this.books,
    required this.onBookTap,
  });

  final List<Book> books;
  final ValueChanged<Book> onBookTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.bookCoverHeightMd,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: AppInsets.pageHorizontal,
        itemCount: books.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: AppSpacing.md),
        itemBuilder: (BuildContext context, int index) {
          final Book book = books[index];
          return TrendingBookItem(
            book: book,
            onTap: () => onBookTap(book),
          );
        },
      ),
    );
  }
}
