import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/app_container.dart';
import '../../../../data/models/catalog_book.dart';
import '../../../../design_system/components/inputs/app_chip.dart';
import '../../../../design_system/components/inputs/app_search_bar.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/components/layout/app_section_header.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../routing/app_router.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/async_body.dart';
import '../../../../shared/widgets/network_book_cover.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../../state/app_config_controller.dart';
import '../../../../state/auth_controller.dart';
import '../../../../state/catalog_controller.dart';
import '../../../announcements/presentation/widgets/announcement_banner.dart';
import '../widgets/featured_book_banner.dart';
import '../widgets/home_hero.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onOpenSearch,
  });

  final VoidCallback onOpenSearch;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<CatalogBook> _featured = const <CatalogBook>[];
  bool _featuredLoading = false;
  bool _featuredStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_featuredStarted) return;
    _featuredStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFeatured());
  }

  Future<void> _loadFeatured() async {
    final AppConfigController config = context.read<AppConfigController>();
    if (!config.config.home.showFeaturedBooks ||
        !config.config.features.featuredBooksEnabled) {
      return;
    }
    final refs = config.config.home.featuredBooks;
    if (refs.isEmpty) return;
    setState(() => _featuredLoading = true);
    final AppContainer container = context.read<AppContainer>();
    final CatalogController catalog = context.read<CatalogController>();
    final List<CatalogBook> resolved = <CatalogBook>[];
    for (final ref in refs) {
      CatalogBook? match;
      for (final CatalogBook book in catalog.books) {
        if (book.id == ref.id) {
          match = book;
          break;
        }
      }
      try {
        match ??= await container.booksRepository.detail(ref.id);
        resolved.add(match);
      } catch (_) {
        // Skip unpublished or missing featured ids.
      }
    }
    if (!mounted) return;
    setState(() {
      _featured = resolved;
      _featuredLoading = false;
    });
  }

  void _openBook(CatalogBook book) {
    AppRouter.pushNamed(context, AppRoutes.bookDetails, arguments: book.id);
  }

  @override
  Widget build(BuildContext context) {
    final AppConfigController config = context.watch<AppConfigController>();
    final CatalogController catalog = context.watch<CatalogController>();
    final AuthController auth = context.watch<AuthController>();
    final home = config.config.home;
    final String appName = config.config.branding.appName;

    return AppScaffold(
      safeAreaBottom: false,
      body: RefreshIndicator(
        onRefresh: () async {
          await catalog.refresh();
          _featuredStarted = false;
          await _loadFeatured();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
          children: [
            const AppGap.lg(),
            Padding(
              padding: AppInsets.pageHorizontal,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.isAuthenticated ? 'Welcome back' : 'Welcome',
                          style: AppTypography.helper(context),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          auth.user?.name ?? appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.display(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const AppGap.lg(),
            Padding(
              padding: AppInsets.pageHorizontal,
              child: GestureDetector(
                onTap: widget.onOpenSearch,
                child: const AbsorbPointer(
                  child: AppSearchBar(readOnly: true, hintText: 'Search books'),
                ),
              ),
            ),
            if (home.showHero) ...[
              const AppGap.lg(),
              HomeHero(home: home, appName: appName),
            ],
            if (config.announcementsVisible) ...[
              const AppGap.lg(),
              SizedBox(
                height: 210,
                child: PageView.builder(
                  itemCount: config.announcements.length,
                  itemBuilder: (BuildContext context, int index) {
                    return AnnouncementBanner(
                      announcement: config.announcements[index],
                    );
                  },
                ),
              ),
            ],
            if (home.showFeaturedBooks &&
                config.config.features.featuredBooksEnabled &&
                (_featuredLoading || _featured.isNotEmpty)) ...[
              const AppGap.xxl(),
              const AppSectionHeader(title: 'Featured'),
              const AppGap.md(),
              if (_featuredLoading)
                const Padding(
                  padding: AppInsets.pageHorizontal,
                  child: ShimmerBox(height: 180),
                )
              else
                FeaturedBookBanner(
                  book: _featured.first,
                  onTap: () => _openBook(_featured.first),
                ),
            ],
            if (home.showCategories &&
                config.config.catalogue.showLanguageFilter) ...[
              const AppGap.xxl(),
              const AppSectionHeader(title: 'Languages'),
              const AppGap.md(),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: AppInsets.pageHorizontal,
                  children: [
                    for (final entry in const <MapEntry<String, String>>[
                      MapEntry('ta', 'Tamil'),
                      MapEntry('en', 'English'),
                      MapEntry('hi', 'Hindi'),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: AppChip(
                          label: entry.value,
                          onTap: () {
                            catalog.applyFilters(language: entry.key);
                            widget.onOpenSearch();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (home.showLatestBooks) ...[
              const AppGap.xxl(),
              AppSectionHeader(
                title: 'Latest books',
                actionLabel: 'See all',
                onAction: widget.onOpenSearch,
              ),
              const AppGap.md(),
              SizedBox(
                height: AppSizes.bookCoverHeightMd + 48,
                child: AsyncBody(
                  loading: catalog.loading && catalog.books.isEmpty,
                  errorMessage: catalog.errorMessage,
                  isEmpty: catalog.books.isEmpty,
                  onRetry: catalog.refresh,
                  emptyTitle: 'No books yet',
                  emptyMessage: 'Published titles will appear here.',
                  loadingPlaceholder: const Padding(
                    padding: AppInsets.pageHorizontal,
                    child: ShimmerBox(height: 156, width: 108),
                  ),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: AppInsets.pageHorizontal,
                    itemCount: catalog.books.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (BuildContext context, int index) {
                      final CatalogBook book = catalog.books[index];
                      return GestureDetector(
                        onTap: () => _openBook(book),
                        child: SizedBox(
                          width: AppSizes.bookCoverWidthMd,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              NetworkBookCover(
                                book: book,
                                width: AppSizes.bookCoverWidthMd,
                                height: AppSizes.bookCoverHeightMd,
                                showTitle: book.coverImage == null,
                              ),
                              const AppGap.xs(),
                              Text(
                                book.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption(context),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
