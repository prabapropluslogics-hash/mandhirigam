import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/app_container.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../data/models/chapter.dart';
import '../../../../data/models/transparent_pages.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/feedback/app_loader.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../data/transparent_page_client.dart';
import '../../data/transparent_page_bytes.dart';
import '../../data/transparent_page_image.dart';
import '../../data/transparent_page_session.dart';
import '../reader_palette.dart';

/// Vertical chrome around each page image. Must stay in sync with
/// [_TransparentPageSlot] so scroll-offset → page-number math is exact.
const double _kPageLabelHeight = 18;
const double _kPageLabelGap = 4;
const double _kPageBottomGap = 12;

/// Original-PDF chapter rendered from authenticated transparent PNGs.
///
/// PDFium is not used. Each page keeps its own image, clip, and zoom.
/// Transparent pixels show the Olaichuvadi surface behind this reader.
class TransparentPngReader extends StatefulWidget {
  const TransparentPngReader({
    super.key,
    required this.chapter,
    required this.package,
    required this.palette,
    required this.session,
    this.client,
    this.apiClient,
    this.onRestricted,
    this.onOpenOriginalPdf,
    this.reloadToken = 0,
    this.readResume,
    this.writeResume,
  });

  final ChapterContent chapter;
  final TransparentPagesDocument package;
  final ReaderPalette palette;
  final TransparentPageSession session;
  final TransparentPageClient? client;
  final ApiClient? apiClient;
  final VoidCallback? onRestricted;
  final VoidCallback? onOpenOriginalPdf;
  final int reloadToken;
  final Future<int?> Function()? readResume;
  final Future<void> Function(int page)? writeResume;

  @override
  State<TransparentPngReader> createState() => _TransparentPngReaderState();
}

class _TransparentPngReaderState extends State<TransparentPngReader> {
  final ScrollController _scroll = ScrollController();
  late TransparentPageClient _client;
  late PageImageCoordinator<_OwnedPageImage> _pages;
  Timer? _progressDebounce;
  int _visiblePage = 1;
  int _epoch = 0;
  bool _resumeApplied = false;
  ApiException? _blocked;

  String get _scope =>
      '${widget.session.userId ?? 'guest'}|${widget.chapter.bookId}|'
      '${widget.chapter.id}|${widget.package.packageId}';

  @override
  void initState() {
    super.initState();
    _client = widget.client ??
        TransparentPageClient(
          widget.apiClient ?? context.read<AppContainer>().apiClient,
        );
    _pages = _newStore();
    widget.session.addListener(_onSession);
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreResume());
  }

  @override
  void didUpdateWidget(covariant TransparentPngReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken ||
        oldWidget.chapter.id != widget.chapter.id ||
        oldWidget.package.packageId != widget.package.packageId) {
      _blocked = null;
      _replaceStore();
    }
  }

  @override
  void dispose() {
    _progressDebounce?.cancel();
    widget.session.removeListener(_onSession);
    _scroll.removeListener(_onScroll);
    _pages.close();
    _client.clear();
    _scroll.dispose();
    super.dispose();
  }

  PageImageCoordinator<_OwnedPageImage> _newStore() {
    return PageImageCoordinator<_OwnedPageImage>(
      maxReady: 5,
      decode: _decodePage,
      release: (_OwnedPageImage owned) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => owned.image.dispose());
      },
      onChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  void _replaceStore() {
    _pages.close();
    _client.clear();
    _pages = _newStore();
    _resumeApplied = false;
    setState(() => _epoch += 1);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreResume());
  }

  void _onSession() {
    if (!mounted) return;
    _blocked = null;
    _replaceStore();
  }

  Future<_OwnedPageImage> _decodePage(int pageNumber) async {
    final int generation = widget.session.generation;
    final String? userId = widget.session.userId;
    final TransparentPage? page = widget.package.pageByNumber(pageNumber);
    if (page == null) {
      throw ApiException(
        statusCode: 404,
        code: 'NOT_FOUND',
        message: 'Page $pageNumber is not in this package.',
      );
    }
    final Uint8List bytes = await _client.fetch(scope: _scope, page: page);
    if (widget.session.generation != generation ||
        widget.session.userId != userId) {
      throw const ApiException(
        statusCode: 0,
        code: 'CANCELLED',
        message: 'Reading was cancelled.',
      );
    }
    final ui.Image image = await decodeTransparentPageImage(
      bytes,
      width: widget.package.width,
      height: widget.package.height,
    );
    if (widget.session.generation != generation ||
        widget.session.userId != userId) {
      image.dispose();
      throw const ApiException(
        statusCode: 0,
        code: 'CANCELLED',
        message: 'Reading was cancelled.',
      );
    }
    return _OwnedPageImage(
      pageNumber: pageNumber,
      identity: '$_scope-$pageNumber',
      image: image,
    );
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final int page = _pageAt(_scroll.offset);
    if (page == _visiblePage) return;
    _pages.setVisible(page);
    setState(() => _visiblePage = page);
    _scheduleProgress(page);
  }

  void _scheduleProgress(int page) {
    _progressDebounce?.cancel();
    _progressDebounce = Timer(const Duration(milliseconds: 450), () {
      _writeProgress(page);
    });
  }

  Future<void> _restoreResume() async {
    if (!mounted || _resumeApplied) return;
    final ChapterDocument? document = widget.chapter.document;
    if (document == null) return;
    int? saved;
    if (widget.readResume != null) {
      saved = await widget.readResume!();
    } else {
      final AppContainer container = context.read<AppContainer>();
      saved = await container.pdfProgressStore.readPage(
        bookId: widget.chapter.bookId,
        chapterId: widget.chapter.id,
        documentSha256: document.sha256,
        packageFingerprint: widget.package.catalogFingerprint,
      );
    }
    if (!mounted || saved == null) {
      _resumeApplied = true;
      return;
    }
    _resumeApplied = true;
    _jumpTo(saved, persist: false);
  }

  Future<void> _writeProgress(int page) async {
    final ChapterDocument? document = widget.chapter.document;
    if (!mounted || document == null) return;
    if (widget.writeResume != null) {
      await widget.writeResume!(page);
      return;
    }
    final AppContainer container = context.read<AppContainer>();
    await container.pdfProgressStore.writePage(
      bookId: widget.chapter.bookId,
      chapterId: widget.chapter.id,
      documentSha256: document.sha256,
      packageFingerprint: widget.package.catalogFingerprint,
      page: page,
    );
  }

  double _pageWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width - 24;

  double _pageHeight(double pageWidth) =>
      pageWidth * (widget.package.height / widget.package.width);

  /// Fixed list-item height: label + gap + image + bottom padding.
  double _itemExtent(double pageWidth) =>
      _kPageLabelHeight +
      _kPageLabelGap +
      _pageHeight(pageWidth) +
      _kPageBottomGap;

  /// One-based document page from the scroll controller's zero-based offset.
  ///
  /// `displayPageNumber = zeroBasedItemIndex + 1`. The list index is derived
  /// from scroll offset / item extent — never from a separate printed label.
  ///
  /// When the viewport is taller than one page, the final item's top cannot
  /// reach offset 0 of the viewport; treat [ScrollPosition.maxScrollExtent]
  /// as the last page so 33/33 (and similar) stay correct.
  int _pageAt(double offset) {
    final int count = widget.package.pageCount;
    if (count <= 1) return 1;
    final double extent = _itemExtent(_pageWidth(context));
    if (extent <= 0) return 1;
    if (_scroll.hasClients) {
      final double max = _scroll.position.maxScrollExtent;
      if (max <= 0) return 1;
      if (offset >= max - 0.5) return count;
    }
    final int zeroBased = (offset / extent).floor();
    final int page = zeroBased + 1;
    if (page < 1) return 1;
    if (page > count) return count;
    return page;
  }

  void _jumpTo(int pageNumber, {bool persist = true}) {
    final int page = pageNumber.clamp(1, widget.package.pageCount);
    final double extent = _itemExtent(_pageWidth(context));
    final double target = (page - 1) * extent;
    if (_scroll.hasClients) {
      final double max = _scroll.position.maxScrollExtent;
      _scroll.jumpTo(target.clamp(0, max));
    }
    _pages.setVisible(page);
    setState(() => _visiblePage = page);
    if (persist) _scheduleProgress(page);
  }

  Future<void> _jumpDialog() async {
    final TextEditingController input =
        TextEditingController(text: '$_visiblePage');
    final int? target = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          title: Text(
            'Go to page',
            style: AppTypography.pageTitle(context).copyWith(
              color: AppColors.neutral0,
            ),
          ),
          content: TextField(
            controller: input,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: const TextStyle(color: AppColors.neutral0),
            decoration: InputDecoration(
              hintText: '1 – ${widget.package.pageCount}',
            ),
            onSubmitted: (String value) {
              Navigator.of(context).pop(int.tryParse(value.trim()));
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(int.tryParse(input.text.trim()));
              },
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
    input.dispose();
    if (target == null || !mounted) return;
    _jumpTo(target);
  }

  void _onPageError(Object error) {
    if (error is! ApiException || _blocked != null) return;
    if (error.isPurchaseRequired ||
        error.isForbidden ||
        error.isUnauthorized ||
        error.isAuthenticationRequired) {
      _pages.close();
      _client.clear();
      setState(() => _blocked = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ApiException? blocked = _blocked;
    if (blocked != null) {
      final bool canRecover = blocked.isPurchaseRequired ||
          blocked.isAuthenticationRequired ||
          blocked.isUnauthorized;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                blocked.userMessage,
                textAlign: TextAlign.center,
                style: AppTypography.body(context).copyWith(
                  color: widget.palette.text,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (canRecover && widget.onRestricted != null)
                AppButton(
                  label: blocked.isPurchaseRequired
                      ? 'Buy now'
                      : 'Continue with Google',
                  isExpanded: false,
                  backgroundColor: widget.palette.accent,
                  foregroundColor: widget.palette.background,
                  onPressed: widget.onRestricted,
                ),
            ],
          ),
        ),
      );
    }

    final double pageWidth = _pageWidth(context);
    final double pageHeight = _pageHeight(pageWidth);
    final double itemExtent = _itemExtent(pageWidth);
    return Stack(
      children: [
        ListView.builder(
          key: ValueKey<String>('png-$_scope-$_epoch'),
          controller: _scroll,
          padding: const EdgeInsets.only(bottom: 64),
          cacheExtent: pageHeight,
          itemExtent: itemExtent,
          itemCount: widget.package.pageCount,
          itemBuilder: (BuildContext context, int index) {
            // List index is zero-based; document page numbers are one-based.
            final int pageNumber = index + 1;
            return _TransparentPageSlot(
              key: ValueKey<String>('$_scope-$pageNumber'),
              store: _pages,
              scroll: _scroll,
              identity: '$_scope-$pageNumber',
              pageNumber: pageNumber,
              pageWidth: pageWidth,
              pageHeight: pageHeight,
              onError: _onPageError,
              onOpenOriginalPdf: widget.onOpenOriginalPdf,
            );
          },
        ),
        Positioned(
          right: AppSpacing.sm,
          bottom: AppSpacing.sm,
          child: _PageChip(
            current: _visiblePage,
            total: widget.package.pageCount,
            onTap: widget.package.pageCount > 1 ? _jumpDialog : null,
          ),
        ),
      ],
    );
  }
}

class _TransparentPageSlot extends StatefulWidget {
  const _TransparentPageSlot({
    super.key,
    required this.store,
    required this.scroll,
    required this.identity,
    required this.pageNumber,
    required this.pageWidth,
    required this.pageHeight,
    required this.onError,
    required this.onOpenOriginalPdf,
  });

  final PageImageCoordinator<_OwnedPageImage> store;
  final ScrollController scroll;
  final String identity;
  final int pageNumber;
  final double pageWidth;
  final double pageHeight;
  final ValueChanged<Object> onError;
  final VoidCallback? onOpenOriginalPdf;

  @override
  State<_TransparentPageSlot> createState() => _TransparentPageSlotState();
}

class _TransparentPageSlotState extends State<_TransparentPageSlot> {
  final TransformationController _zoom = TransformationController();
  double _scale = 1;

  @override
  void initState() {
    super.initState();
    _zoom.addListener(_onZoom);
    widget.store.pin(widget.pageNumber);
  }

  @override
  void dispose() {
    widget.store.unpin(widget.pageNumber);
    _zoom.removeListener(_onZoom);
    _zoom.dispose();
    super.dispose();
  }

  void _onZoom() {
    final double scale = _zoom.value.getMaxScaleOnAxis();
    if (!mounted || (scale - _scale).abs() < 0.01) return;
    setState(() => _scale = scale);
  }

  /// A one-finger drag at 1× belongs to the chapter list. The viewer accepts
  /// that gesture so pinch can start on the page, then hands the movement
  /// back to the list until the page is actually zoomed.
  void _forwardScroll(ScaleUpdateDetails details) {
    if (_scale > 1.01 || details.pointerCount >= 2) return;
    if (!widget.scroll.hasClients) return;
    final double next = widget.scroll.offset - details.focalPointDelta.dy;
    final double max = widget.scroll.position.maxScrollExtent;
    widget.scroll.jumpTo(next.clamp(0, max));
  }

  @override
  Widget build(BuildContext context) {
    final _OwnedPageImage? owned = widget.store.readyFor(widget.pageNumber);
    final Object? error = widget.store.errorFor(widget.pageNumber);
    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onError(error);
      });
    }
    final bool ownsPage = owned == null ||
        transparentImageBelongsToPage(
          imagePage: owned.pageNumber,
          widgetPage: widget.pageNumber,
          imageIdentity: owned.identity,
          widgetIdentity: widget.identity,
          closed: widget.store.isClosed,
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, _kPageBottomGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _kPageLabelHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Page ${widget.pageNumber}',
                style: AppTypography.caption(context).copyWith(
                  color: AppColors.readerInkSoft,
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(height: _kPageLabelGap),
          SizedBox(
            width: widget.pageWidth,
            height: widget.pageHeight,
            child: ClipRect(
              child: InteractiveViewer(
                transformationController: _zoom,
                minScale: 1,
                maxScale: 4,
                panEnabled: _scale > 1.01,
                scaleEnabled: true,
                clipBehavior: Clip.hardEdge,
                boundaryMargin: EdgeInsets.zero,
                onInteractionUpdate: _forwardScroll,
                child: SizedBox(
                  width: widget.pageWidth,
                  height: widget.pageHeight,
                  child: _pageBody(owned, error, ownsPage),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageBody(_OwnedPageImage? owned, Object? error, bool ownsPage) {
    if (!ownsPage || widget.store.isClosed) {
      return const SizedBox.expand();
    }
    if (owned != null) {
      return RawImage(
        image: owned.image,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.medium,
      );
    }
    if (error != null) {
      final bool offerPdf = transparentFailureOffersPdf(error);
      final String message = error is ApiException
          ? error.userMessage
          : 'Could not load this page.';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.readerInk),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => widget.store.retry(widget.pageNumber),
                child: const Text('Retry'),
              ),
              if (offerPdf && widget.onOpenOriginalPdf != null)
                TextButton(
                  onPressed: widget.onOpenOriginalPdf,
                  child: const Text('Open original PDF'),
                ),
            ],
          ),
        ),
      );
    }
    return const Center(child: AppLoader());
  }
}

class _OwnedPageImage {
  _OwnedPageImage({
    required this.pageNumber,
    required this.identity,
    required this.image,
  });

  final int pageNumber;
  final String identity;
  final ui.Image image;
}

class _PageChip extends StatelessWidget {
  const _PageChip({
    required this.current,
    required this.total,
    required this.onTap,
  });

  final int current;
  final int total;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.readerChrome.withOpacity(0.88),
      borderRadius: BorderRadius.circular(AppRadii.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.full),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs + 2,
          ),
          child: Text(
            '$current / $total',
            style: AppTypography.caption(context).copyWith(
              color: AppColors.readerChromeIcon,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
