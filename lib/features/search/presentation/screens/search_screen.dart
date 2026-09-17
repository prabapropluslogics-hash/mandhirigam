import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/catalog_book.dart';
import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/inputs/app_chip.dart';
import '../../../../design_system/components/inputs/app_search_bar.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../routing/app_router.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/async_body.dart';
import '../../../../shared/widgets/catalog_book_card.dart';
import '../../../../state/app_config_controller.dart';
import '../../../../state/catalog_controller.dart';
import '../../../../state/library_controller.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.onCancel,
  });

  final VoidCallback onCancel;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final CatalogController catalog = context.read<CatalogController>();
      catalog.setSearch(value);
      catalog.load(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final CatalogController catalog = context.watch<CatalogController>();
    final LibraryController library = context.watch<LibraryController>();
    final catalogue = context.watch<AppConfigController>().config.catalogue;

    return AppScaffold(
      safeAreaBottom: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppGap.md(),
          Padding(
            padding: AppInsets.pageHorizontal,
            child: Row(
              children: [
                Expanded(
                  child: AppSearchBar(
                    controller: _controller,
                    hintText: 'Search title or author',
                    onChanged: _onSearchChanged,
                  ),
                ),
                AppTextButton(
                  label: 'Cancel',
                  compact: true,
                  onPressed: widget.onCancel,
                ),
              ],
            ),
          ),
          const AppGap.md(),
          if (catalogue.showLanguageFilter)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: AppInsets.pageHorizontal,
                children: [
                  _FilterChip(
                    label: 'All languages',
                    selected: catalog.language == null,
                    onTap: () => catalog.applyFilters(
                      language: null,
                      accessType: catalog.accessType,
                    ),
                  ),
                  for (final entry in const <MapEntry<String, String>>[
                    MapEntry('ta', 'Tamil'),
                    MapEntry('en', 'English'),
                    MapEntry('hi', 'Hindi'),
                  ])
                    _FilterChip(
                      label: entry.value,
                      selected: catalog.language == entry.key,
                      onTap: () => catalog.applyFilters(
                        language: entry.key,
                        accessType: catalog.accessType,
                      ),
                    ),
                ],
              ),
            ),
          const AppGap.sm(),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: AppInsets.pageHorizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: catalog.accessType == null,
                  onTap: () => catalog.applyFilters(
                    language: catalog.language,
                    accessType: null,
                  ),
                ),
                if (catalogue.showFreeBooks)
                  _FilterChip(
                    label: 'Free',
                    selected: catalog.accessType == 'FREE',
                    onTap: () => catalog.applyFilters(
                      language: catalog.language,
                      accessType: 'FREE',
                    ),
                  ),
                if (catalogue.showPaidBooks)
                  _FilterChip(
                    label: 'Paid',
                    selected: catalog.accessType == 'PAID',
                    onTap: () => catalog.applyFilters(
                      language: catalog.language,
                      accessType: 'PAID',
                    ),
                  ),
              ],
            ),
          ),
          const AppGap.md(),
          Padding(
            padding: AppInsets.pageHorizontal,
            child: Text(
              catalog.loading
                  ? 'Searching…'
                  : '${catalog.pagination?.total ?? catalog.books.length} titles',
              style: AppTypography.helper(context),
            ),
          ),
          const AppGap.sm(),
          Expanded(
            child: AsyncBody(
              loading: catalog.loading && catalog.books.isEmpty,
              errorMessage: catalog.errorMessage,
              isEmpty: catalog.books.isEmpty,
              onRetry: catalog.refresh,
              emptyTitle: catalog.search.trim().isEmpty
                  ? 'No books yet'
                  : 'No matching titles',
              emptyMessage: catalog.search.trim().isEmpty
                  ? 'Published books will appear in the catalogue.'
                  : 'Try another search or filter.',
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification notification) {
                  if (notification.metrics.pixels >
                      notification.metrics.maxScrollExtent - 240) {
                    catalog.loadMore();
                  }
                  return false;
                },
                child: RefreshIndicator(
                  onRefresh: catalog.refresh,
                  child: ListView.builder(
                    padding: AppInsets.pageHorizontal,
                    itemCount: catalog.books.length + (catalog.loadingMore ? 1 : 0),
                    itemBuilder: (BuildContext context, int index) {
                      if (index >= catalog.books.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final CatalogBook book = catalog.books[index];
                      return CatalogBookCard(
                        book: book,
                        owned: library.owns(book.id),
                        onTap: () {
                          AppRouter.pushNamed(
                            context,
                            AppRoutes.bookDetails,
                            arguments: book.id,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: AppChip(
        label: label,
        selected: selected,
        variant: selected ? AppChipVariant.goldOutline : AppChipVariant.surface,
        onTap: onTap,
      ),
    );
  }
}
