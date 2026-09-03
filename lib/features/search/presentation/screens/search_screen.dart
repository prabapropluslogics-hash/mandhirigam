import 'package:flutter/material.dart';

import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/inputs/app_chip.dart';
import '../../../../design_system/components/inputs/app_search_bar.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../routing/app_router.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/data/mock_catalog.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/widgets/book_list_item.dart';
import '../widgets/filter_bottom_sheet.dart';

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
  late final TextEditingController _controller =
      TextEditingController(text: 'winter');
  FilterSelection _filters = FilterSelection.initial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Book> get _results => MockCatalog.search(_controller.text);

  Future<void> _openFilters() async {
    final FilterSelection? next = await showFilterBottomSheet(
      context,
      initial: _filters,
    );
    if (next != null) {
      setState(() => _filters = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Book> results = _results;

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
                    autofocus: false,
                    onChanged: (_) => setState(() {}),
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
          const AppGap.lg(),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: AppInsets.pageHorizontal,
              itemCount: MockCatalog.recentSearches.length,
              separatorBuilder: (context, index) =>
                  const AppGap.sm(axis: AppGapAxis.horizontal),
              itemBuilder: (BuildContext context, int index) {
                final String query = MockCatalog.recentSearches[index];
                return AppChip(
                  label: query,
                  onTap: () {
                    _controller.text = query;
                    setState(() {});
                  },
                );
              },
            ),
          ),
          const AppGap.md(),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: AppInsets.pageHorizontal,
              itemCount: MockCatalog.filterShortcuts.length + 1,
              separatorBuilder: (context, index) =>
                  const AppGap.sm(axis: AppGapAxis.horizontal),
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return AppChip(
                    label: 'Filters',
                    leadingIcon: AppIcons.filters,
                    variant: AppChipVariant.goldFilled,
                    onTap: _openFilters,
                  );
                }
                return AppChip(
                  label: MockCatalog.filterShortcuts[index - 1],
                  onTap: _openFilters,
                );
              },
            ),
          ),
          const AppGap.lg(),
          Padding(
            padding: AppInsets.pageHorizontal,
            child: Text(
              _controller.text.trim().toLowerCase() == 'winter'
                  ? '128 results'
                  : '${results.length} results',
              style: AppTypography.helper(context),
            ),
          ),
          const AppGap.sm(),
          Expanded(
            child: ListView.builder(
              padding: AppInsets.pageHorizontal,
              itemCount: results.length,
              itemBuilder: (BuildContext context, int index) {
                final Book book = results[index];
                return BookListItem(
                  book: book,
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
        ],
      ),
    );
  }
}
