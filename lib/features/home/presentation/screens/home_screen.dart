import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/app_container.dart';
import '../../../../data/models/catalog_book.dart';
import '../../../../data/models/chapter.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/components/layout/app_section_header.dart';
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
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../../state/app_config_controller.dart';
import '../../../../state/auth_controller.dart';
import '../../../../state/book_access.dart';
import '../../../../state/catalog_controller.dart';
import '../../../../state/library_controller.dart';
import '../../../announcements/presentation/widgets/announcement_banner.dart';
import '../../../book_details/presentation/screens/book_details_screen.dart';
import '../../state/home_language_preference.dart';
import '../widgets/continue_reading_card.dart';
import '../widgets/featured_book_banner.dart';
import '../widgets/home_banner.dart';
import '../widgets/home_carousel.dart';
import '../widgets/home_header.dart';
import '../widgets/home_language_selector.dart';
import '../widgets/home_search_entry.dart';
import '../widgets/latest_book_card.dart';

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
  /// Roughly how many Latest Books cards show across the screen.
  static const double _cardsPerScreen = 2.6;
  static const double _minCardWidth = 116;
  static const double _maxCardWidth = 150;

  List<CatalogBook> _featured = const <CatalogBook>[];
  bool _featuredLoading = false;
  bool _featuredStarted = false;

  /// Home's own catalogue instance, so the Home language filter never touches
  /// the shared catalogue that Search uses.
  late final CatalogController _homeCatalog = CatalogController(
    context.read<AppContainer>().booksRepository,
  )..addListener(_onHomeCatalogChanged);
  HomeLanguagePreference? _languagePreference;
  HomeLanguage _language = HomeLanguage.initial;
  bool _homeInitialized = false;
  bool _initialLoadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_homeInitialized) {
      _homeInitialized = true;
      final HomeLanguagePreference preference =
          context.read<HomeLanguagePreference>();
      _languagePreference = preference..addListener(_onLanguageChanged);
      _language = preference.language;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _loadInitialHomeCatalog());
    }
    if (_featuredStarted) return;
    _featuredStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFeatured());
  }

  @override
  void dispose() {
    _languagePreference?.removeListener(_onLanguageChanged);
    _homeCatalog.removeListener(_onHomeCatalogChanged);
    // An in-flight load notifies when it completes; disposing first would
    // make that notification throw. Without listeners it is simply dropped.
    if (!_homeCatalog.loading && !_homeCatalog.loadingMore) {
      _homeCatalog.dispose();
    }
    super.dispose();
  }

  void _onHomeCatalogChanged() {
    if (mounted) setState(() {});
  }

  bool get _languageFilterEnabled {
    final config = context.read<AppConfigController>().config;
    return config.home.showCategories && config.catalogue.showLanguageFilter;
  }

  Future<void> _loadHomeCatalog() {
    return _homeCatalog.applyFilters(
      language: _languageFilterEnabled ? _language.code : null,
    );
  }

  /// Waits for the saved Home language so the first request already uses it.
  Future<void> _loadInitialHomeCatalog() async {
    await _languagePreference?.load();
    if (!mounted) return;
    _initialLoadStarted = true;
    final HomeLanguage saved = _languagePreference?.language ?? _language;
    if (saved != _language) setState(() => _language = saved);
    await _loadHomeCatalog();
  }

  void _onLanguageChanged() {
    final HomeLanguage? next = _languagePreference?.language;
    if (!mounted || next == null || next == _language) return;
    setState(() => _language = next);
    if (_initialLoadStarted) _loadHomeCatalog();
  }

  Future<void> _chooseLanguage() async {
    final HomeLanguage? picked =
        await showHomeLanguageSheet(context, current: _language);
    if (!mounted || picked == null || picked == _language) return;
    _languagePreference?.select(picked);
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
    AppRouter.pushNamed(
      context,
      AppRoutes.bookDetails,
      arguments: BookDetailsArgs(bookId: book.id, preview: book),
    );
  }

  /// Featured books in the Home language, without duplicates.
  List<CatalogBook> get _featuredForLanguage {
    final bool filter = _languageFilterEnabled;
    final Set<String> seen = <String>{};
    return <CatalogBook>[
      for (final CatalogBook book in _featured)
        if ((!filter || book.language.trim().toLowerCase() == _language.code) &&
            seen.add(book.id))
          book,
    ];
  }

  /// There is no reading-progress source yet (no progress API and nothing
  /// stored by the reader), so there is never a genuine entry to resume.
  ContinueReadingEntry? get _continueReading => null;

  /// Opens the reader only when [BookAccess] already allows reading without
  /// a sign-in step; otherwise Book Details runs the normal access flow.
  Future<void> _resume(ContinueReadingEntry entry) async {
    final CatalogBook book = entry.book;
    final LibraryController library = context.read<LibraryController>();
    final BookAccess access = BookAccess.resolve(
      book: book,
      authenticated: context.read<AuthController>().isAuthenticated,
      owned: library.owns(book.id),
      guestCanReadFree: context
          .read<AppConfigController>()
          .config
          .guestAccess
          .allowGuestFreeBookReading,
      ownershipLoading: library.loading && !library.loaded,
    );
    if (!access.isRead || access.requiresSignIn || access.resolvingOwnership) {
      _openBook(book);
      return;
    }
    List<ChapterSummary> chapters;
    try {
      chapters =
          await context.read<AppContainer>().booksRepository.chapters(book.id);
    } catch (_) {
      chapters = const <ChapterSummary>[];
    }
    if (!mounted) return;
    if (!chapters.any((ChapterSummary c) => c.id == entry.chapterId)) {
      _openBook(book);
      return;
    }
    AppRouter.pushNamed(
      context,
      AppRoutes.reader,
      arguments: ReaderArgs(
        bookId: book.id,
        chapterId: entry.chapterId,
        bookTitle: book.title,
        chapters: chapters,
        accessType: book.accessType,
      ),
    );
  }

  String _greeting(AuthController auth) {
    if (!auth.isAuthenticated) return 'Welcome';
    final String name = auth.user?.name.trim() ?? '';
    return name.isEmpty ? 'Welcome back' : 'Welcome back, $name';
  }

  @override
  Widget build(BuildContext context) {
    final AppConfigController config = context.watch<AppConfigController>();
    final CatalogController catalog = context.watch<CatalogController>();
    final AuthController auth = context.watch<AuthController>();
    final home = config.config.home;
    final features = config.config.features;
    final bool featuredEnabled =
        home.showFeaturedBooks && features.featuredBooksEnabled;
    final List<CatalogBook> featured = _featuredForLanguage;
    final ContinueReadingEntry? continueReading = home.showContinueReading &&
            features.continueReadingEnabled &&
            features.readingProgressEnabled
        ? _continueReading
        : null;

    return BrandTheme(
      child: AppScaffold(
        useSafeArea: false,
        body: Stack(
          children: [
            const Positioned.fill(child: AmbientBackground()),
            SafeArea(
              bottom: false,
              child: RefreshIndicator(
                color: AppColors.brandPrimary,
                backgroundColor: AppColors.surfaceDark,
                onRefresh: () async {
                  await Future.wait<void>(
                    <Future<void>>[catalog.refresh(), _homeCatalog.refresh()],
                  );
                  _featuredStarted = false;
                  await _loadFeatured();
                },
                child: ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.huge),
                  children: [
                    const AppGap.lg(),
                    HomeHeader(greeting: _greeting(auth)),
                    if (home.showHero) ...[
                      const AppGap.xl(),
                      const HomeBanner(),
                    ],
                    const AppGap.xl(),
                    HomeSearchEntry(onTap: widget.onOpenSearch),
                    if (_languageFilterEnabled) ...[
                      const AppGap.md(),
                      _buildLanguageRow(context),
                    ],
                    if (continueReading != null) ...[
                      const AppGap.xxxl(),
                      const AppSectionHeader(
                        title: 'Continue Reading',
                        subtitle: 'Pick up where you left off',
                      ),
                      const AppGap.lg(),
                      ContinueReadingCard(
                        entry: continueReading,
                        onContinue: () => _resume(continueReading),
                      ),
                    ],
                    if (config.announcementsVisible) ...[
                      const AppGap.xxl(),
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
                    if (featuredEnabled &&
                        (_featuredLoading || featured.isNotEmpty)) ...[
                      const AppGap.xxxl(),
                      const AppSectionHeader(
                        title: 'Featured',
                        subtitle: 'Handpicked for you',
                      ),
                      const AppGap.lg(),
                      if (_featuredLoading)
                        Padding(
                          padding: AppInsets.pageHorizontal,
                          child: ShimmerBox(
                            height: AppSizes.featuredCardHeight,
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                          ),
                        )
                      else
                        HomeCarousel(
                          key: ValueKey<String>(
                            featured.map((CatalogBook b) => b.id).join(','),
                          ),
                          autoPlay: false,
                          itemCount: featured.length,
                          itemBuilder: (BuildContext context, int index) {
                            final CatalogBook book = featured[index];
                            return FeaturedBookBanner(
                              book: book,
                              onTap: () => _openBook(book),
                            );
                          },
                        ),
                    ],
                    if (home.showLatestBooks) ...[
                      const AppGap.xxxl(),
                      AppSectionHeader(
                        title: 'Latest books',
                        subtitle: 'Explore something new',
                        actionLabel: 'See all',
                        onAction: widget.onOpenSearch,
                      ),
                      const AppGap.lg(),
                      _buildLatestRail(context),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageRow(BuildContext context) {
    return Padding(
      padding: AppInsets.pageHorizontal,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing books in',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppTypography.bodySmall(context).copyWith(
                color: AppColors.textSecondaryDark,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          HomeLanguageSelector(
            language: _language,
            onTap: _homeCatalog.loading ? null : _chooseLanguage,
          ),
        ],
      ),
    );
  }

  Widget _buildLatestRail(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double cardWidth =
        ((screenWidth - AppSpacing.pageHorizontal * 2 - AppSpacing.lg * 2) /
                _cardsPerScreen)
            .clamp(_minCardWidth, _maxCardWidth);
    final List<CatalogBook> books = _homeCatalog.books;
    final LibraryController library = context.watch<LibraryController>();

    return SizedBox(
      height: LatestBookCard.heightFor(context, cardWidth),
      child: AsyncBody(
        loading: _homeCatalog.loading,
        errorMessage: _homeCatalog.errorMessage,
        isEmpty: books.isEmpty,
        onRetry: _homeCatalog.refresh,
        emptyTitle: 'No books yet',
        emptyMessage: _languageFilterEnabled
            ? 'No ${_language.label} titles yet. Try another language.'
            : 'Published titles will appear here.',
        loadingPlaceholder: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: AppInsets.pageHorizontal,
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
          itemBuilder: (_, __) => Align(
            alignment: Alignment.topCenter,
            child: ShimmerBox(
              width: cardWidth,
              height: cardWidth * LatestBookCard.coverAspect,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
          ),
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: AppInsets.pageHorizontal,
          clipBehavior: Clip.none,
          itemCount: books.length,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
          itemBuilder: (BuildContext context, int index) {
            final CatalogBook book = books[index];
            return LatestBookCard(
              book: book,
              owned: library.owns(book.id),
              width: cardWidth,
              onTap: () => _openBook(book),
            );
          },
        ),
      ),
    );
  }
}
