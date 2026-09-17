import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/app_container.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../data/models/catalog_book.dart';
import '../../../../data/models/chapter.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/components/navigation/app_tab_bar.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../routing/app_router.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/widgets/access_badge.dart';
import '../../../../shared/widgets/async_body.dart';
import '../../../../shared/widgets/network_book_cover.dart';
import '../../../../state/app_config_controller.dart';
import '../../../../state/auth_controller.dart';
import '../../../../state/library_controller.dart';
import '../../../payment/presentation/payment_flow.dart';
import '../widgets/book_info_item.dart';

class BookDetailsScreen extends StatefulWidget {
  const BookDetailsScreen({super.key, required this.bookId});

  final String bookId;

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  String _tab = 'overview';
  bool _expanded = false;
  CatalogBook? _book;
  List<ChapterSummary> _chapters = const <ChapterSummary>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final AppContainer container = context.read<AppContainer>();
      final CatalogBook book =
          await container.booksRepository.detail(widget.bookId);
      final List<ChapterSummary> chapters =
          await container.booksRepository.chapters(widget.bookId);
      if (!mounted) return;
      setState(() {
        _book = book;
        _chapters = chapters;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.userMessage;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load this book.';
        _loading = false;
      });
    }
  }

  Future<void> _openChapter(ChapterSummary chapter) async {
    final CatalogBook? book = _book;
    if (book == null) return;
    final AuthController auth = context.read<AuthController>();
    final guest = context.read<AppConfigController>().config.guestAccess;
    final bool owned = context.read<LibraryController>().owns(book.id);

    if (book.isPaid && !auth.isAuthenticated) {
      final bool? signedIn = await AppRouter.pushNamed<bool>(
        context,
        AppRoutes.login,
        arguments: 'Sign in to purchase and read this book.',
      );
      if (signedIn != true) return;
    }

    if (!mounted) return;
    if (book.isPaid && auth.isAuthenticated && !owned) {
      await startPaymentFlow(context, book);
      return;
    }

    if (!mounted) return;
    if (book.isFree && !auth.isAuthenticated && !guest.allowGuestFreeBookReading) {
      await AppRouter.pushNamed<bool>(
        context,
        AppRoutes.login,
        arguments: 'Sign in to read this book.',
      );
      return;
    }

    if (!mounted) return;
    AppRouter.pushNamed(
      context,
      AppRoutes.reader,
      arguments: ReaderArgs(
        bookId: book.id,
        chapterId: chapter.id,
        bookTitle: book.title,
        chapters: _chapters,
        accessType: book.accessType,
      ),
    );
  }

  Future<void> _primaryAction() async {
    final CatalogBook? book = _book;
    if (book == null) return;
    if (_chapters.isNotEmpty) {
      await _openChapter(_chapters.first);
      return;
    }
    if (book.isPaid) {
      await startPaymentFlow(context, book);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LibraryController library = context.watch<LibraryController>();
    final AuthController auth = context.watch<AuthController>();
    final CatalogBook? book = _book;
    final bool owned = book != null && library.owns(book.id);

    return AppScaffold(
      safeAreaBottom: false,
      body: AsyncBody(
        loading: _loading,
        errorMessage: _error,
        isEmpty: !_loading && book == null,
        onRetry: _load,
        emptyTitle: 'Book unavailable',
        child: book == null
            ? const SizedBox.shrink()
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                      children: [
                        Padding(
                          padding: AppInsets.pageHorizontal,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AppIconButton(
                              icon: AppIcons.back,
                              tooltip: 'Back',
                              onPressed: () => AppRouter.pop(context),
                            ),
                          ),
                        ),
                        const AppGap.md(),
                        Center(
                          child: NetworkBookCover(
                            book: book,
                            width: AppSizes.bookCoverWidthLg,
                            height: AppSizes.bookCoverHeightLg,
                            showTitle: book.coverImage == null,
                          ),
                        ),
                        const AppGap.xl(),
                        Padding(
                          padding: AppInsets.pageHorizontal,
                          child: Column(
                            children: [
                              Text(
                                book.title,
                                textAlign: TextAlign.center,
                                style: AppTypography.bookTitle(
                                  context,
                                  fontSize: 26,
                                ),
                              ),
                              const AppGap.xs(),
                              Text(
                                'by ${book.author}',
                                style: AppTypography.helper(context),
                              ),
                              const AppGap.md(),
                              AccessBadge(book: book, owned: owned),
                              const AppGap.xxl(),
                              BookInfoRow(
                                chapters: '${_chapters.length}',
                                access: book.accessType,
                                language: book.languageLabel,
                              ),
                            ],
                          ),
                        ),
                        const AppGap.lg(),
                        AppTabBar(
                          selectedValue: _tab,
                          onChanged: (String value) =>
                              setState(() => _tab = value),
                          tabs: const <AppTabItem>[
                            AppTabItem(label: 'Overview', value: 'overview'),
                            AppTabItem(label: 'Chapters', value: 'chapters'),
                          ],
                        ),
                        Padding(
                          padding: AppInsets.page,
                          child: _tab == 'overview'
                              ? _overview(book)
                              : _chapterList(owned, auth.isAuthenticated),
                        ),
                      ],
                    ),
                  ),
                  _ActionBar(
                    book: book,
                    owned: owned,
                    authenticated: auth.isAuthenticated,
                    onPressed: _primaryAction,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _overview(CatalogBook book) {
    final String visible = _expanded || book.description.length < 180
        ? book.description
        : '${book.description.substring(0, 180).trim()}… ';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(visible, style: AppTypography.body(context)),
        if (book.description.length > 180)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(_expanded ? 'Show less' : 'Read more'),
          ),
      ],
    );
  }

  Widget _chapterList(bool owned, bool authenticated) {
    if (_chapters.isEmpty) {
      return const Text('No published chapters yet.');
    }
    return Column(
      children: [
        for (final ChapterSummary chapter in _chapters)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${chapter.chapterNumber}. ${chapter.title}',
              style: AppTypography.body(context),
            ),
            trailing: const Icon(AppIcons.chevronRight),
            onTap: () => _openChapter(chapter),
          ),
      ],
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.book,
    required this.owned,
    required this.authenticated,
    required this.onPressed,
  });

  final CatalogBook book;
  final bool owned;
  final bool authenticated;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final String label;
    if (book.isFree) {
      label = 'Read now';
    } else if (owned) {
      label = 'Read now';
    } else if (!authenticated) {
      label = 'Sign in to buy';
    } else {
      label = 'Buy ${book.priceLabel}';
    }

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: AppInsets.page,
          child: AppButton(label: label, onPressed: onPressed),
        ),
      ),
    );
  }
}

class ReaderArgs {
  const ReaderArgs({
    required this.bookId,
    required this.chapterId,
    required this.bookTitle,
    required this.chapters,
    required this.accessType,
  });

  final String bookId;
  final String chapterId;
  final String bookTitle;
  final List<ChapterSummary> chapters;
  final String accessType;
}
