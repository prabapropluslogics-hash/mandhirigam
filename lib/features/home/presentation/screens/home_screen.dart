import 'package:flutter/material.dart';

import '../../../../design_system/components/inputs/app_search_bar.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/components/layout/app_section_header.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../routing/app_router.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/data/mock_catalog.dart';
import '../../../../shared/models/book.dart';
import '../widgets/continue_reading_card.dart';
import '../widgets/featured_book_card.dart';
import '../widgets/home_header.dart';
import '../widgets/trending_book_item.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenSearch,
  });

  final VoidCallback onOpenSearch;

  void _openBook(BuildContext context, Book book) {
    AppRouter.pushNamed(context, AppRoutes.bookDetails, arguments: book.id);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      safeAreaBottom: false,
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        children: [
          const AppGap.lg(),
          const HomeHeader(),
          const AppGap.lg(),
          Padding(
            padding: AppInsets.pageHorizontal,
            child: GestureDetector(
              onTap: onOpenSearch,
              child: const AbsorbPointer(
                child: AppSearchBar(readOnly: true),
              ),
            ),
          ),
          const AppGap.lg(),
          ContinueReadingCard(
            book: MockCatalog.quietHours,
            onTap: () => _openBook(context, MockCatalog.quietHours),
          ),
          const AppGap.xxl(),
          const AppSectionHeader(title: 'Featured'),
          const AppGap.md(),
          FeaturedBookCard(
            book: MockCatalog.amberSea,
            onTap: () => _openBook(context, MockCatalog.amberSea),
          ),
          const AppGap.xxl(),
          AppSectionHeader(
            title: 'Trending now',
            actionLabel: 'See all',
            onAction: onOpenSearch,
          ),
          const AppGap.md(),
          TrendingBooksRow(
            books: MockCatalog.trending,
            onBookTap: (Book book) => _openBook(context, book),
          ),
        ],
      ),
    );
  }
}
