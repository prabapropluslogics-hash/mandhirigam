import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/app_container.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../data/models/catalog_book.dart';
import '../../../../data/models/chapter.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/buttons/app_button_shared.dart';
import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/feedback/app_loader.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/components/navigation/app_tab_bar.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../design_system/theme/brand_theme.dart';
import '../../../../routing/app_router.dart';
import '../../../../routing/app_routes.dart';
import '../../../../services/share_service.dart';
import '../../../../shared/widgets/access_badge.dart';
import '../../../../shared/widgets/ambient_background.dart';
import '../../../../shared/widgets/async_body.dart';
import '../../../../shared/widgets/network_book_cover.dart';
import '../../../../state/app_config_controller.dart';
import '../../../../state/auth_controller.dart';
import '../../../../state/book_access.dart';
import '../../../../state/library_controller.dart';
import '../../../../state/payment_controller.dart';
import '../../../auth/presentation/require_sign_in.dart';
import '../../../payment/presentation/payment_flow.dart';
import '../widgets/book_info_item.dart';

class BookDetailsArgs {
  const BookDetailsArgs({required this.bookId, this.preview});

  final String bookId;
  final CatalogBook? preview;
}

class BookDetailsScreen extends StatefulWidget {
  const BookDetailsScreen({
    super.key,
    required this.bookId,
    this.preview,
  });

  final String bookId;
  final CatalogBook? preview;

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  /// Descriptions longer than this (UTF-16 units) start collapsed.
  static const int _previewLength = 180;

  /// Cover height as a multiple of its width (classic 2:3 book proportion).
  static const double _coverAspect = 1.48;

  String _tab = 'overview';
  bool _expanded = false;
  CatalogBook? _book;
  List<ChapterSummary> _chapters = const <ChapterSummary>[];
  bool _loading = true;
  bool _actionBusy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _book = widget.preview;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = _book == null;
      _error = null;
    });
    try {
      final AppContainer container = context.read<AppContainer>();
      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        container.booksRepository.detail(widget.bookId),
        container.booksRepository.chapters(widget.bookId),
      ]);
      if (!mounted) return;
      setState(() {
        _book = results[0] as CatalogBook;
        _chapters = results[1] as List<ChapterSummary>;
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

  BookAccess _currentAccess(CatalogBook book) {
    final LibraryController library = context.read<LibraryController>();
    return BookAccess.resolve(
      book: book,
      authenticated: context.read<AuthController>().isAuthenticated,
      owned: library.owns(book.id),
      guestCanReadFree: context
          .read<AppConfigController>()
          .config
          .guestAccess
          .allowGuestFreeBookReading,
    );
  }

  /// Primary button (`chapter == null`) or a chapter row. Signs in when
  /// needed and always comes back to this screen.
  Future<void> _handleAction([ChapterSummary? chapter]) async {
    final CatalogBook? book = _book;
    if (book == null || _actionBusy) return;
    setState(() => _actionBusy = true);
    try {
      if (book.isPaid) {
        await _readOrBuyPaid(book, chapter);
      } else {
        await _readFree(book, chapter);
      }
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _readFree(CatalogBook book, ChapterSummary? chapter) async {
    if (_currentAccess(book).requiresSignIn &&
        !await requireSignIn(context,
            message: 'Sign in to read ${book.title}.')) {
      return;
    }
    if (mounted) await _openReader(book, chapter);
  }

  Future<void> _readOrBuyPaid(CatalogBook book, ChapterSummary? chapter) async {
    if (!await requireSignIn(context,
        message: 'Sign in to buy ${book.title}.')) {
      return;
    }
    if (!mounted) return;
    final LibraryController library = context.read<LibraryController>();
    if (!library.loaded) await library.refresh();
    if (!mounted) return;
    // Owned (per the backend library): read; never start another order.
    if (library.owns(book.id)) {
      await _openReader(book, chapter);
      return;
    }
    // Purchase keeps the user here; the CTA turns into "Read now".
    await startPaymentFlow(
      context,
      book,
      onReadNow: () => _openReader(book, chapter),
    );
  }

  Future<void> _openReader(CatalogBook book, ChapterSummary? chapter) async {
    final ChapterSummary? target =
        chapter ?? (_chapters.isEmpty ? null : _chapters.first);
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No chapters are available yet.')),
      );
      return;
    }
    await AppRouter.pushNamed(
      context,
      AppRoutes.reader,
      arguments: ReaderArgs(
        bookId: book.id,
        chapterId: target.id,
        bookTitle: book.title,
        chapters: _chapters,
        accessType: book.accessType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LibraryController library = context.watch<LibraryController>();
    final PaymentController payment = context.watch<PaymentController>();
    final CatalogBook? book = _book;
    final bool owned = book != null && library.owns(book.id);
    final bool showSkeleton = _loading && book == null;
    final BookAccess? access =
        book == null ? null : BookAccess.of(context, book);
    final ShareService share = context.read<AppContainer>().shareService;

    return BrandTheme(
      child: AppScaffold(
        useSafeArea: false,
        // As the bottom bar, floating snackbars appear above the primary CTA
        // instead of covering it.
        bottomNavigationBar: book == null || access == null
            ? null
            : _ActionBar(
                access: access,
                paymentPhase: payment.activeBookId == book.id
                    ? payment.phase
                    : PaymentPhase.idle,
                priceLabel:
                    book.isPaid && book.price > 0 ? book.priceLabel : null,
                isLoading: _actionBusy || (_loading && _chapters.isEmpty),
                onPressed: _handleAction,
              ),
        body: Stack(
          children: [
            const Positioned.fill(child: AmbientBackground()),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _DetailsHeader(
                    onBack: () => AppRouter.pop(context),
                    onShare: book != null && share.canShareBooks
                        ? (BuildContext buttonContext) => share.shareBook(
                              buttonContext,
                              bookId: book.id,
                              title: book.title,
                            )
                        : null,
                  ),
                  Expanded(
                    child: AsyncBody(
                      loading: showSkeleton,
                      errorMessage: _error,
                      isEmpty: !_loading && book == null,
                      onRetry: _load,
                      emptyTitle: 'Book unavailable',
                      emptyMessage: 'This title could not be opened.',
                      child: book == null || access == null
                          ? const SizedBox.shrink()
                          : _buildContent(context, book, owned, access),
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

  Widget _buildContent(
    BuildContext context,
    CatalogBook book,
    bool owned,
    BookAccess access,
  ) {
    final String author = book.author.trim();
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        const AppGap.sm(),
        _buildHero(context, book),
        const AppGap.xxl(),
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
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimaryDark,
                ).copyWith(height: 1.35),
              ),
              if (author.isNotEmpty) ...[
                const AppGap.sm(),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'by ',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                      TextSpan(
                        text: author,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.splashTagline,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall(context).copyWith(
                    color: AppColors.textSecondaryDark,
                    height: 1.4,
                  ),
                ),
              ],
              const AppGap.lg(),
              AccessBadge(book: book, owned: owned),
              const AppGap.xxl(),
              BookInfoRow(
                chapters:
                    _loading && _chapters.isEmpty ? '…' : '${_chapters.length}',
                access: book.isFree ? 'Free' : 'Paid',
                language: book.languageLabel,
              ),
            ],
          ),
        ),
        const AppGap.xl(),
        Padding(
          padding: AppInsets.pageHorizontal,
          child: AppTabBar(
            selectedValue: _tab,
            onChanged: (String value) => setState(() => _tab = value),
            tabs: const <AppTabItem>[
              AppTabItem(label: 'Overview', value: 'overview'),
              AppTabItem(label: 'Chapters', value: 'chapters'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.xl,
            AppSpacing.pageHorizontal,
            AppSpacing.lg,
          ),
          child: _tab == 'overview'
              ? _overview(book)
              : _chapterList(locked: !access.isRead),
        ),
      ],
    );
  }

  Widget _buildHero(BuildContext context, CatalogBook book) {
    final double coverWidth =
        (MediaQuery.sizeOf(context).width * 0.44).clamp(132.0, 184.0);
    final double coverHeight = coverWidth * _coverAspect;
    final BorderRadius radius = BorderRadius.circular(AppRadii.sm + 2);

    return SizedBox(
      height: coverHeight + AppSpacing.xxl,
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: SizedBox(
              width: coverWidth * 2.4,
              height: coverHeight + AppSpacing.xxl,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.62,
                    colors: [
                      AppColors.splashGlow.withOpacity(0.16),
                      AppColors.splashGlow.withOpacity(0.05),
                      AppColors.splashGlow.withOpacity(0),
                    ],
                    stops: const [0, 0.55, 1],
                  ),
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowWithOpacity(0.6),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: AppColors.brandPrimary.withOpacity(0.12),
                  blurRadius: 36,
                ),
              ],
            ),
            child: Stack(
              children: [
                NetworkBookCover(
                  book: book,
                  width: coverWidth,
                  height: coverHeight,
                  showTitle: book.coverImage == null,
                  borderRadius: radius,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        border: Border.all(
                          color: AppColors.splashTagline.withOpacity(0.1),
                          width: 0.6,
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
    );
  }

  /// Collapsed preview that never splits a Tamil grapheme cluster and, when
  /// possible, ends on a word boundary.
  String _collapsed(String text) {
    final StringBuffer buffer = StringBuffer();
    for (final String grapheme in text.characters) {
      if (buffer.length + grapheme.length > _previewLength) break;
      buffer.write(grapheme);
    }
    String cut = buffer.toString();
    final int space = cut.lastIndexOf(RegExp(r'\s'));
    if (space > _previewLength * 0.6) cut = cut.substring(0, space);
    return '${cut.trimRight()}…';
  }

  Widget _overview(CatalogBook book) {
    final bool hasDescription = book.description.trim().isNotEmpty;
    final String description = hasDescription
        ? book.description
        : 'No description available for this book.';
    final bool collapsible = description.length > _previewLength;
    final String visible =
        _expanded || !collapsible ? description : _collapsed(description);
    final TextStyle paragraph = AppTypography.body(context).copyWith(
      fontSize: 15,
      height: 1.75,
      color: hasDescription
          ? AppColors.textPrimaryDark.withOpacity(0.86)
          : AppColors.textSecondaryDark,
    );
    final List<String> paragraphs = visible
        .split(RegExp(r'\n\s*\n'))
        .map((String p) => p.trim())
        .where((String p) => p.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('About this book'),
        const AppGap.md(),
        for (int i = 0; i < paragraphs.length; i++) ...[
          if (i > 0) const AppGap.md(),
          Text(paragraphs[i], style: paragraph),
        ],
        if (collapsible) ...[
          const AppGap.xs(),
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.brandPrimary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, AppSizes.minTouchTarget),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_expanded ? 'Show less' : 'Read more'),
                const SizedBox(width: AppSpacing.xxs),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(AppIcons.expandMore, size: AppSizes.iconMd),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _chapterList({required bool locked}) {
    if (_loading && _chapters.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_chapters.isEmpty) {
      return Text(
        'No published chapters yet.',
        style: AppTypography.helper(context),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Eyebrow(
          _chapters.length == 1 ? '1 chapter' : '${_chapters.length} chapters',
        ),
        const AppGap.sm(),
        for (int i = 0; i < _chapters.length; i++)
          _ChapterRow(
            chapter: _chapters[i],
            locked: locked,
            showDivider: i < _chapters.length - 1,
            onTap: _actionBusy ? null : () => _handleAction(_chapters[i]),
          ),
      ],
    );
  }
}

/// Floating circular back (and share) buttons over the page atmosphere.
class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({required this.onBack, this.onShare});

  final VoidCallback onBack;
  final ValueChanged<BuildContext>? onShare;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          _CircleButton(
            icon: AppIcons.back,
            tooltip: 'Back',
            iconSize: AppSizes.iconSm + 2,
            onPressed: onBack,
          ),
          const Spacer(),
          if (onShare != null)
            Builder(
              builder: (BuildContext buttonContext) => _CircleButton(
                icon: AppIcons.share,
                tooltip: 'Share',
                iconSize: AppSizes.iconMd,
                onPressed: () => onShare!(buttonContext),
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.iconSize,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final double iconSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceDark.withOpacity(0.72),
      shape: CircleBorder(
        side: BorderSide(
          color: AppColors.brandPrimary.withOpacity(0.22),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: AppIconButton(
        icon: icon,
        tooltip: tooltip,
        iconSize: iconSize,
        color: AppColors.textPrimaryDark,
        onPressed: onPressed,
      ),
    );
  }
}

/// Short gold rule followed by a small uppercase label.
class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 1,
          color: AppColors.brandPrimary.withOpacity(0.8),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            text.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption(context).copyWith(
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w600,
              color: AppColors.brandPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.chapter,
    required this.locked,
    required this.showDivider,
    required this.onTap,
  });

  final ChapterSummary chapter;

  /// The book still has to be bought; tapping runs the normal buy flow.
  final bool locked;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String number = chapter.chapterNumber.toString().padLeft(2, '0');
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(
                    bottom: BorderSide(
                      color: AppColors.dividerDark,
                      width: AppSizes.dividerThickness,
                    ),
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHAPTER $number',
                        style: AppTypography.caption(context).copyWith(
                          fontSize: 10.5,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandPrimary.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        chapter.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(context).copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                          color: AppColors.textPrimaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(
                  locked ? AppIcons.lockOutline : AppIcons.chevronRight,
                  size: locked ? AppSizes.iconSm + 2 : AppSizes.iconLg,
                  color: locked
                      ? AppColors.textSecondaryDark
                      : AppColors.brandPrimary.withOpacity(0.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.access,
    required this.onPressed,
    this.paymentPhase = PaymentPhase.idle,
    this.priceLabel,
    this.isLoading = false,
  });

  final BookAccess access;
  final VoidCallback onPressed;

  /// Purchase progress for this book; drives "Processing…" / "Verifying…".
  final PaymentPhase paymentPhase;

  /// Real price of a paid book, shown as "Buy for ₹X" while it can be bought.
  final String? priceLabel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bool paying = !access.isRead &&
        (paymentPhase == PaymentPhase.creatingOrder ||
            paymentPhase == PaymentPhase.checkout ||
            paymentPhase == PaymentPhase.verifying);
    final String label = switch (paymentPhase) {
      _ when access.isRead => access.label,
      PaymentPhase.creatingOrder ||
      PaymentPhase.checkout when paying =>
        'Processing…',
      PaymentPhase.verifying when paying => 'Verifying payment…',
      _ when priceLabel != null => 'Buy for $priceLabel',
      _ => access.label,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.splashBase,
        border: Border(
          top: BorderSide(
            color: AppColors.brandPrimary.withOpacity(0.14),
            width: 0.6,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowWithOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.md,
            AppSpacing.pageHorizontal,
            AppSpacing.md,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadii.buttonBorder,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPrimary.withOpacity(0.28),
                  blurRadius: 22,
                  spreadRadius: -4,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: AppButton(
              key: const Key('book-primary-action'),
              label: label,
              size: AppButtonSize.large,
              leadingIcon: access.isRead ? AppIcons.read : null,
              leading: paying
                  ? const AppLoader(
                      size: AppSizes.iconMd,
                      strokeWidth: AppSizes.loaderStrokeWidthCompact,
                      color: AppColors.textOnBrand,
                    )
                  : null,
              isLoading: (isLoading && !paying) || access.resolvingOwnership,
              backgroundColor: AppColors.brandPrimary,
              foregroundColor: AppColors.textOnBrand,
              onPressed: onPressed,
            ),
          ),
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
