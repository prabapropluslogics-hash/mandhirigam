import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/catalog_book.dart';
import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/inputs/app_search_bar.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../design_system/theme/brand_theme.dart';
import '../../../../routing/app_router.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/ambient_background.dart';
import '../../../../shared/widgets/async_body.dart';
import '../../../../state/app_config_controller.dart';
import '../../../../state/catalog_controller.dart';
import '../../../../state/library_controller.dart';
import '../../../book_details/presentation/screens/book_details_screen.dart';
import '../widgets/search_result_tile.dart';

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

    return BrandTheme(
      child: AppScaffold(
        useSafeArea: false,
        body: Stack(
          children: [
            const Positioned.fill(child: AmbientBackground()),
            SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppGap.lg(),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.pageHorizontal,
                      right: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SearchField(
                            controller: _controller,
                            onChanged: _onSearchChanged,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        AppTextButton(
                          label: 'Cancel',
                          compact: true,
                          foregroundColor: AppColors.brandPrimary,
                          onPressed: widget.onCancel,
                        ),
                      ],
                    ),
                  ),
                  const AppGap.lg(),
                  if (catalogue.showLanguageFilter) ...[
                    _FilterRow(
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
                    const AppGap.sm(),
                  ],
                  _FilterRow(
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
                  const AppGap.xl(),
                  Padding(
                    padding: AppInsets.pageHorizontal,
                    child: _ResultCount(
                      loading: catalog.loading,
                      count: catalog.pagination?.total ?? catalog.books.length,
                    ),
                  ),
                  const AppGap.xs(),
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
                          color: AppColors.brandPrimary,
                          backgroundColor: AppColors.surfaceDark,
                          onRefresh: catalog.refresh,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.pageHorizontal,
                              0,
                              AppSpacing.pageHorizontal,
                              AppSpacing.lg,
                            ),
                            itemCount: catalog.books.length +
                                (catalog.loadingMore ? 1 : 0),
                            separatorBuilder: (_, __) => const Divider(
                              height: AppSizes.dividerThickness,
                              thickness: AppSizes.dividerThickness,
                              color: AppColors.dividerDark,
                            ),
                            itemBuilder: (BuildContext context, int index) {
                              if (index >= catalog.books.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(AppSpacing.lg),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              final CatalogBook book = catalog.books[index];
                              return SearchResultTile(
                                book: book,
                                owned: library.owns(book.id),
                                onTap: () {
                                  AppRouter.pushNamed(
                                    context,
                                    AppRoutes.bookDetails,
                                    arguments: BookDetailsArgs(
                                      bookId: book.id,
                                      preview: book,
                                    ),
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Elevated charcoal search field whose border and glow turn gold on focus.
class _SearchField extends StatefulWidget {
  const _SearchField({required this.controller, required this.onChanged});

  static const double _height = 52;

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: AppRadii.searchBarBorder,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.surfaceMutedDark, AppColors.surfaceDark],
        ),
        border: Border.all(
          color: AppColors.brandPrimary.withOpacity(_focused ? 0.7 : 0.2),
          width: _focused ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowWithOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.brandPrimary.withOpacity(_focused ? 0.14 : 0),
            blurRadius: 18,
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(
          inputDecorationTheme: theme.inputDecorationTheme.copyWith(
            fillColor: AppColors.surfaceDark.withOpacity(0),
            prefixIconColor: _focused
                ? AppColors.brandPrimary
                : AppColors.brandPrimary.withOpacity(0.75),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.searchBarBorder,
              borderSide: BorderSide.none,
            ),
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
          textSelectionTheme: theme.textSelectionTheme.copyWith(
            cursorColor: AppColors.brandPrimary,
            selectionColor: AppColors.brandPrimary.withOpacity(0.3),
            selectionHandleColor: AppColors.brandPrimary,
          ),
        ),
        child: Focus(
          onFocusChange: (bool focused) => setState(() => _focused = focused),
          child: AppSearchBar(
            controller: widget.controller,
            hintText: 'Search title or author',
            height: _SearchField._height,
            onChanged: widget.onChanged,
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrolling chip row that sizes itself to its chips, so large
/// text never clips them.
class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: AppInsets.pageHorizontal,
      child: Row(children: children),
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
    final ShapeBorder shape = StadiumBorder(
      side: BorderSide(
        color: selected
            ? AppColors.brandPrimary.withOpacity(0.85)
            : AppColors.brandPrimary.withOpacity(0.14),
        width: selected ? 1 : 0.8,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected
              ? AppColors.brandPrimary.withOpacity(0.14)
              : AppColors.surfaceDark.withOpacity(0.85),
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            highlightColor: AppColors.brandPrimary.withOpacity(0.08),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSizes.chipHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(
                    label,
                    style: AppTypography.caption(context).copyWith(
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: 0.2,
                      color: selected
                          ? AppColors.brandAccent
                          : AppColors.textPrimaryDark.withOpacity(0.88),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "2 titles" with the number in gold, trailed by a fading gold hairline.
class _ResultCount extends StatelessWidget {
  const _ResultCount({required this.loading, required this.count});

  final bool loading;
  final int count;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = AppTypography.bodySmall(context).copyWith(
      color: AppColors.textSecondaryDark,
    );
    return Row(
      children: [
        Text.rich(
          loading
              ? const TextSpan(text: 'Searching…')
              : TextSpan(
                  children: [
                    TextSpan(
                      text: '$count',
                      style: const TextStyle(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const TextSpan(text: ' titles'),
                  ],
                ),
          style: base,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            height: 0.6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.brandPrimary.withOpacity(0.28),
                  AppColors.brandPrimary.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
