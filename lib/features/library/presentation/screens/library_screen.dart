import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/catalog_book.dart';
import '../../../../data/models/library_item.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../design_system/theme/brand_theme.dart';
import '../../../../routing/app_router.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/ambient_background.dart';
import '../../../../shared/widgets/async_body.dart';
import '../../../../shared/widgets/page_header.dart';
import '../../../auth/presentation/widgets/google_continue_button.dart';
import '../../../startup/presentation/widgets/splash_brand.dart';
import '../../../../state/auth_controller.dart';
import '../../../../state/catalog_controller.dart';
import '../../../../state/library_controller.dart';
import '../../../book_details/presentation/screens/book_details_screen.dart';
import '../widgets/library_book_tile.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final AuthController auth = context.watch<AuthController>();
    final LibraryController library = context.read<LibraryController>();
    if (!_requested && auth.isAuthenticated) {
      _requested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        library.load();
      });
    }
    if (!auth.isAuthenticated) {
      _requested = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthController auth = context.watch<AuthController>();
    final LibraryController library = context.watch<LibraryController>();

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
                    padding: AppInsets.pageHorizontal,
                    child: PageHeader(
                      title: 'Library',
                      subtitle: auth.isAuthenticated
                          ? 'Lifetime titles you have purchased.'
                          : 'Your personal collection',
                    ),
                  ),
                  const AppGap.lg(),
                  Expanded(
                    child: !auth.isAuthenticated
                        ? _GuestLibrary(
                            onSignIn: () {
                              AppRouter.pushNamed(
                                context,
                                AppRoutes.login,
                                arguments: 'Sign in to open your library.',
                              );
                            },
                          )
                        : AsyncBody(
                            loading: library.loading && library.items.isEmpty,
                            errorMessage: library.errorMessage,
                            isEmpty: library.items.isEmpty,
                            onRetry: library.refresh,
                            emptyTitle: 'Your library is empty',
                            emptyMessage:
                                'Purchased books will appear here after payment is verified.',
                            child: NotificationListener<ScrollNotification>(
                              onNotification:
                                  (ScrollNotification notification) {
                                if (notification.metrics.pixels >
                                    notification.metrics.maxScrollExtent -
                                        240) {
                                  library.loadMore();
                                }
                                return false;
                              },
                              child: RefreshIndicator(
                                color: AppColors.brandPrimary,
                                backgroundColor: AppColors.surfaceDark,
                                onRefresh: library.refresh,
                                child: _Bookshelf(
                                  items: library.items,
                                  loadingMore: library.loadingMore,
                                  catalog: context.watch<CatalogController>(),
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

/// Owned books as a responsive shelf grid with a title count.
class _Bookshelf extends StatelessWidget {
  const _Bookshelf({
    required this.items,
    required this.loadingMore,
    required this.catalog,
  });

  static const double _minTileWidth = 140;
  static const double _maxTileWidth = 190;

  final List<LibraryItem> items;
  final bool loadingMore;
  final CatalogController catalog;

  /// Library entries carry no author; use the catalogue's when it has one.
  CatalogBook _bookFor(LibraryItem item) {
    final CatalogBook base = item.asBook;
    for (final CatalogBook known in catalog.books) {
      if (known.id == item.bookId && known.author.trim().isNotEmpty) {
        return CatalogBook(
          id: base.id,
          title: base.title,
          description: base.description,
          author: known.author,
          language: base.language,
          coverImage: base.coverImage,
          accessType: base.accessType,
          price: base.price,
          currency: base.currency,
        );
      }
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = AppSpacing.lg;
        final double available =
            constraints.maxWidth - AppSpacing.pageHorizontal * 2;
        final int columns =
            ((available + gap) / (_minTileWidth + gap)).floor().clamp(2, 6);
        final double tileWidth = ((available - gap * (columns - 1)) / columns)
            .clamp(0.0, _maxTileWidth);
        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: AppInsets.pageHorizontal,
              sliver: SliverToBoxAdapter(
                child: _ShelfCount(count: items.length),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.lg,
                AppSpacing.pageHorizontal,
                AppSpacing.huge,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: gap,
                  mainAxisSpacing: AppSpacing.xl,
                  mainAxisExtent: LibraryBookTile.heightFor(context, tileWidth),
                ),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    final LibraryItem item = items[index];
                    final CatalogBook book = _bookFor(item);
                    return Align(
                      alignment: Alignment.topLeft,
                      child: LibraryBookTile(
                        book: book,
                        width: tileWidth,
                        onTap: () {
                          AppRouter.pushNamed(
                            context,
                            AppRoutes.bookDetails,
                            arguments: BookDetailsArgs(
                              bookId: item.bookId,
                              preview: book,
                            ),
                          );
                        },
                      ),
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),
            if (loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ShelfCount extends StatelessWidget {
  const _ShelfCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$count',
                style: const TextStyle(color: AppColors.brandAccent),
              ),
              TextSpan(text: count == 1 ? ' book owned' : ' books owned'),
            ],
          ),
          style: AppTypography.label(context).copyWith(
            color: AppColors.textSecondaryDark,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            height: 0.8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.brandPrimary.withOpacity(0.35),
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

/// Signed-out Library: a small glowing emblem, a short invitation and the
/// sign-in call to action.
class _GuestLibrary extends StatelessWidget {
  const _GuestLibrary({required this.onSignIn});

  static const double _maxContentWidth = 360;

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: AppInsets.page,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - AppSpacing.pageVertical * 2,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _GlowingEmblem(),
                const AppGap.xxl(),
                Text(
                  'Your library is waiting for you',
                  textAlign: TextAlign.center,
                  style: AppTypography.bookTitle(
                    context,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const AppGap.sm(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: Text(
                    'Sign in to access your purchased books and keep your '
                    'collection in one place.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall(context).copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ),
                const AppGap.xxl(),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                  child: GoogleContinueButton(onPressed: onSignIn),
                ),
                const AppGap.xxl(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GlowingEmblem extends StatelessWidget {
  const _GlowingEmblem();

  static const double _size = 132;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.brandPrimary.withOpacity(0.16),
              AppColors.brandPrimary.withOpacity(0.04),
              AppColors.brandPrimary.withOpacity(0),
            ],
            stops: const [0, 0.55, 1],
          ),
        ),
        child: const Center(child: SplashEmblem(size: 76)),
      ),
    );
  }
}
