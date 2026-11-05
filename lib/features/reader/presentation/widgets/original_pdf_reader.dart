import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:provider/provider.dart';

import '../../../../core/app_container.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../data/models/chapter.dart';
import '../../../../data/services/authenticated_pdf_range_source.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/feedback/app_empty_state.dart';
import '../../../../design_system/components/feedback/app_loader.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../data/pdf_progress_store.dart';
import '../reader_palette.dart';

/// Original opaque PDF pages inside the existing Olaichuvadi parchment frame.
///
/// Does **not** attempt transparent compositing or white-pixel keying. The
/// PDF page remains PDFium's opaque render; parchment shows in gutters/gaps.
class OriginalPdfReader extends StatefulWidget {
  const OriginalPdfReader({
    super.key,
    required this.chapter,
    required this.palette,
    this.onRestricted,
  });

  final ChapterContent chapter;
  final ReaderPalette palette;
  final VoidCallback? onRestricted;

  @override
  State<OriginalPdfReader> createState() => _OriginalPdfReaderState();
}

class _OriginalPdfReaderState extends State<OriginalPdfReader> {
  final PdfViewerController _controller = PdfViewerController();

  AuthenticatedPdfRangeSource? _source;
  PdfDocumentRef? _documentRef;
  int _initialPage = 1;
  int _currentPage = 1;
  int _pageCount = 0;
  bool _ready = false;
  bool _opening = true;
  ApiException? _apiError;
  String? _error;
  Timer? _progressDebounce;
  int _session = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void didUpdateWidget(covariant OriginalPdfReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapter.id != widget.chapter.id ||
        oldWidget.chapter.document?.sha256 != widget.chapter.document?.sha256) {
      _open();
    }
  }

  @override
  void dispose() {
    _progressDebounce?.cancel();
    // Do not dispose [_source] here. [PdfDocumentRefCustom.onDispose] owns
    // that lifecycle. Disposing early while PDFium GetBlock is in flight makes
    // pdfrx 1.0.84 report -1 (treated as success) with a dirty buffer.
    _source = null;
    super.dispose();
  }

  Future<void> _open() async {
    final int session = ++_session;
    final ChapterContent chapter = widget.chapter;
    final String? metaError = chapter.pdfOpenError();
    if (metaError != null) {
      setState(() {
        _opening = false;
        _ready = false;
        _error = metaError;
        _apiError = null;
        _documentRef = null;
      });
      return;
    }

    final ChapterDocument document = chapter.document!;
    debugPrint(
      '[pdf-reader] open book=${chapter.bookId} chapter=${chapter.id} '
      'mode=${chapter.readerMode.wireName} size=${document.size} '
      'pages=${document.pageCount} sha256=${document.sha256} '
      'path=${document.downloadPath}',
    );
    final AppContainer container = context.read<AppContainer>();
    final PdfProgressStore progress = container.pdfProgressStore;
    progress.bindUser(container.authController.user?.id);

    setState(() {
      _opening = true;
      _ready = false;
      _error = null;
      _apiError = null;
      _documentRef = null;
      _pageCount = document.pageCount;
      _currentPage = 1;
    });

    final AuthenticatedPdfRangeSource? previous = _source;
    _source = null;
    // Drop the previous document ref first so its onDispose runs before we
    // create a new source. Avoids two live sources racing on the same viewer.
    previous?.dispose();

    final AuthenticatedPdfRangeSource source = AuthenticatedPdfRangeSource(
      client: container.apiClient,
      document: document,
      bookId: chapter.bookId,
      chapterId: chapter.id,
    );
    _source = source;

    final int? saved = await progress.readPage(
      bookId: chapter.bookId,
      chapterId: chapter.id,
      documentSha256: document.sha256,
    );
    if (!mounted || session != _session) {
      source.dispose();
      return;
    }

    final int initial = (saved ?? 1).clamp(1, document.pageCount);
    // Load the whole document into memory when it fits the app upload ceiling.
    // Progressive GetBlock (default 1MB threshold) issued ~300+ Range calls for
    // this 5.1MB book; a failed call was mapped to PDFium "success" via -1.
    final int memoryCap = document.size <= ChapterDocument.maxAcceptedBytes
        ? document.size
        : AuthenticatedPdfRangeSource.rangeChunkBytes;
    setState(() {
      _initialPage = initial;
      _currentPage = initial;
      _documentRef = PdfDocumentRefCustom(
        fileSize: source.fileSize,
        read: source.read,
        sourceName: source.sourceName,
        maxSizeToCacheOnMemory: memoryCap,
        onDispose: source.dispose,
      );
      _opening = false;
      _ready = true;
    });
  }

  void _onPageChanged(int? pageNumber) {
    if (pageNumber == null || pageNumber < 1) return;
    setState(() => _currentPage = pageNumber);
    _progressDebounce?.cancel();
    _progressDebounce = Timer(const Duration(milliseconds: 450), () {
      _persistPage(pageNumber);
    });
  }

  Future<void> _persistPage(int page) async {
    final ChapterDocument? doc = widget.chapter.document;
    if (doc == null || !mounted) return;
    final AppContainer container = context.read<AppContainer>();
    await container.pdfProgressStore.writePage(
      bookId: widget.chapter.bookId,
      chapterId: widget.chapter.id,
      documentSha256: doc.sha256,
      page: page,
    );
  }

  Future<void> _jumpDialog() async {
    final TextEditingController input =
        TextEditingController(text: '$_currentPage');
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
              hintText: '1 – $_pageCount',
              hintStyle: TextStyle(
                color: AppColors.neutral0.withOpacity(0.45),
              ),
            ),
            onSubmitted: (String value) {
              final int? page = int.tryParse(value.trim());
              Navigator.of(context).pop(page);
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
    final int page = target.clamp(1, _pageCount);
    if (!_controller.isReady) return;
    try {
      await _controller.goToPage(pageNumber: page);
    } catch (error) {
      debugPrint('PDF page jump failed: $error');
    }
  }

  void _handleViewerError(Object error) {
    final Object? rangeError = _source?.lastError;
    debugPrint(
      'PDF viewer error: $error | lastRangeError=$rangeError | '
      'book=${widget.chapter.bookId} chapter=${widget.chapter.id} '
      'ranges=${_source?.rangeRequestCount ?? 0} '
      'downloaded=${_source?.bytesDownloaded ?? 0}',
    );
    if (!mounted) return;
    final Object effective = error is ApiException
        ? error
        : (rangeError is ApiException ? rangeError : error);
    if (effective is ApiException) {
      setState(() {
        _apiError = effective;
        _error = effective.userMessage;
        _ready = false;
      });
      return;
    }
    setState(() {
      _error = 'Could not open this PDF.';
      _ready = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_opening) {
      return const AppLoaderPage();
    }
    if (_apiError != null &&
        (_apiError!.isPurchaseRequired ||
            _apiError!.isAuthenticationRequired ||
            _apiError!.isUnauthorized ||
            _apiError!.isForbidden)) {
      final bool canRecoverWithAuthOrPurchase = _apiError!.isPurchaseRequired ||
          _apiError!.isAuthenticationRequired ||
          _apiError!.isUnauthorized;
      return AppEmptyState(
        icon: AppIcons.lock,
        title: _apiError!.isPurchaseRequired
            ? 'Purchase required'
            : (_apiError!.isAuthenticationRequired || _apiError!.isUnauthorized)
                ? 'Sign in to continue'
                : 'Access restricted',
        message: _apiError!.userMessage,
        action: canRecoverWithAuthOrPurchase && widget.onRestricted != null
            ? AppButton(
                label: _apiError!.isPurchaseRequired
                    ? 'Buy now'
                    : 'Continue with Google',
                isExpanded: false,
                backgroundColor: widget.palette.accent,
                foregroundColor: widget.palette.background,
                onPressed: widget.onRestricted,
              )
            : AppButton(
                label: 'Retry',
                isExpanded: false,
                backgroundColor: widget.palette.accent,
                foregroundColor: widget.palette.background,
                onPressed: _open,
              ),
      );
    }
    if (_error != null || !_ready || _documentRef == null) {
      return AppEmptyState(
        icon: AppIcons.error,
        title: 'Could not open PDF',
        message: _error ?? 'This document could not be opened.',
        action: AppButton(
          label: 'Retry',
          isExpanded: false,
          backgroundColor: widget.palette.accent,
          foregroundColor: widget.palette.background,
          onPressed: _open,
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: PdfViewer(
            _documentRef!,
            controller: _controller,
            initialPageNumber: _initialPage,
            params: PdfViewerParams(
              // Transparent viewport so parchment shows in gutters/gaps.
              // PDF page bitmaps stay opaque white from PDFium.
              backgroundColor: Colors.transparent,
              margin: 18,
              maxScale: 4,
              minScale: 0.5,
              useAlternativeFitScaleAsMinScale: true,
              panEnabled: true,
              scaleEnabled: true,
              enableTextSelection: false,
              pageDropShadow: BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(2, 3),
              ),
              onPageChanged: _onPageChanged,
              onDocumentChanged: (PdfDocument? doc) {
                if (doc == null || !mounted) return;
                final int actual = doc.pages.length;
                final int meta = widget.chapter.document?.pageCount ?? 0;
                if (meta > 0 && actual != meta) {
                  debugPrint(
                    'PDF pageCount mismatch meta=$meta pdfrx=$actual '
                    'chapter=${widget.chapter.id}',
                  );
                }
                setState(() {
                  _pageCount = actual > 0 ? actual : _pageCount;
                  if (_currentPage > _pageCount) {
                    _currentPage = _pageCount;
                  }
                });
              },
              errorBannerBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
                PdfDocumentRef documentRef,
              ) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _handleViewerError(error);
                });
                return const SizedBox.shrink();
              },
              loadingBannerBuilder: (
                BuildContext context,
                int bytesDownloaded,
                int? totalBytes,
              ) {
                return const Center(child: AppLoader());
              },
            ),
          ),
        ),
        Positioned(
          right: AppSpacing.sm,
          bottom: AppSpacing.sm,
          child: _PageChip(
            current: _currentPage,
            total: _pageCount,
            onTap: _pageCount > 1 ? _jumpDialog : null,
          ),
        ),
      ],
    );
  }
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
    final String label = total > 0 ? '$current / $total' : '$current';
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
            label,
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
