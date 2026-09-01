import 'package:flutter/material.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/feedback/app_empty_state.dart';
import '../../../../design_system/components/inputs/app_chip.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/components/layout/app_section_header.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../routing/app_router.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/data/mock_catalog.dart';
import '../../../../shared/models/book.dart';
import '../widgets/downloaded_covers_row.dart';
import '../widgets/library_book_item.dart';
import '../widgets/reading_streak_card.dart';

enum LibraryFilter { continueReading, downloaded, wishlist }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.onOpenSearch,
  });

  final VoidCallback onOpenSearch;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  LibraryFilter _filter = LibraryFilter.continueReading;

  void _openBook(Book book) {
    AppRouter.pushNamed(context, AppRoutes.bookDetails, arguments: book.id);
  }

  void _openReader(Book book) {
    AppRouter.pushNamed(context, AppRoutes.reader, arguments: book.id);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      safeAreaBottom: false,
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        children: [
          const AppGap.lg(),
          Padding(
            padding: AppInsets.pageHorizontal,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'My library',
                    style: AppTypography.bookTitle(context, fontSize: 28),
                  ),
                ),
                AppIconButton(
                  icon: AppIcons.search,
                  tooltip: 'Search library',
                  onPressed: widget.onOpenSearch,
                ),
              ],
            ),
          ),
          const AppGap.lg(),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: AppInsets.pageHorizontal,
            child: Row(
              children: [
                AppChip(
                  label: 'Continue reading',
                  selected: _filter == LibraryFilter.continueReading,
                  onTap: () => setState(
                    () => _filter = LibraryFilter.continueReading,
                  ),
                ),
                const AppGap.sm(axis: AppGapAxis.horizontal),
                AppChip(
                  label: 'Downloaded',
                  selected: _filter == LibraryFilter.downloaded,
                  onTap: () =>
                      setState(() => _filter = LibraryFilter.downloaded),
                ),
                const AppGap.sm(axis: AppGapAxis.horizontal),
                AppChip(
                  label: 'Wishlist',
                  selected: _filter == LibraryFilter.wishlist,
                  onTap: () =>
                      setState(() => _filter = LibraryFilter.wishlist),
                ),
              ],
            ),
          ),
          const AppGap.lg(),
          if (_filter == LibraryFilter.continueReading) ...[
            const ReadingStreakCard(streak: MockCatalog.readingStreak),
            const AppGap.lg(),
            Padding(
              padding: AppInsets.pageHorizontal,
              child: Column(
                children: [
                  for (final Book book in MockCatalog.continueReading)
                    LibraryBookItem(
                      book: book,
                      onTap: () => _openReader(book),
                    ),
                ],
              ),
            ),
            const AppGap.lg(),
            AppSectionHeader(
              title: 'Downloaded',
              actionLabel: 'Manage',
              onAction: () {},
            ),
            const AppGap.md(),
            DownloadedCoversRow(
              books: MockCatalog.downloaded,
              onBookTap: _openBook,
            ),
          ] else if (_filter == LibraryFilter.downloaded)
            Padding(
              padding: AppInsets.pageHorizontal,
              child: Column(
                children: [
                  for (final Book book in MockCatalog.downloaded)
                    LibraryBookItem(
                      book: book,
                      onTap: () => _openBook(book),
                    ),
                ],
              ),
            )
          else if (MockCatalog.wishlist.isEmpty)
            const AppEmptyState(
              title: 'Wishlist',
              message: 'Save titles to find them later.',
            )
          else
            Padding(
              padding: AppInsets.pageHorizontal,
              child: Column(
                children: [
                  for (final Book book in MockCatalog.wishlist)
                    LibraryBookItem(
                      book: book,
                      onTap: () => _openBook(book),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
