import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

import 'phase21_render_gate.dart';
import '../features/reader/presentation/reader_palette.dart';
import '../features/reader/presentation/widgets/reader_paper.dart';
import '../features/reader/state/reader_preferences.dart';

/// Debug-only screen for the Phase 2 33-page transparent PDF.
///
/// Uses production `pdfrx` 1.0.84 [PdfPage.render] with
/// [Colors.transparent] so soft-mask alpha composites onto the Flutter
/// background. Pages render when they enter the scroll cache and their
/// bitmaps are disposed when they leave it. Renders are serialized, and
/// each page is clipped to its own slot so one page cannot paint over the next.
class Phase12TransparencyScreen extends StatefulWidget {
  const Phase12TransparencyScreen({super.key});

  static const String assetPath = 'assets/debug/phase2-all-33-transparent.pdf';

  static const int expectedBytes = 11735347;
  static const int expectedPages = 33;

  /// Pages called out for close inspection. PDF order matches the source.
  static const List<int> focusPages = <int>[1, 7, 13, 16, 19, 25, 33];

  @override
  State<Phase12TransparencyScreen> createState() =>
      _Phase12TransparencyScreenState();
}

enum _BgMode { white, checkerboard, parchment }

class _Phase12TransparencyScreenState extends State<Phase12TransparencyScreen> {
  static const double _labelHeight = 20;
  static const double _labelGap = 6;
  static const double _pageGap = 18;
  static const double _dpiScale = 150 / 72;

  final ScrollController _scroll = ScrollController();
  final Phase21RenderGate _renderGate = Phase21RenderGate();
  final Map<int, int> _renderMs = <int, int>{};

  PdfDocument? _document;
  _BgMode _bg = _BgMode.parchment;
  bool _loading = true;
  String? _error;
  String _nativeNote = 'pdfrx 1.0.84 / waiting for Android PDFium load';
  int _loadMs = 0;
  double _zoom = 1;
  int _visiblePage = 1;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _open();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _document?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_document == null || !mounted) return;
    final double width = MediaQuery.sizeOf(context).width - 24;
    final int page = _pageAt(_scroll.offset, width);
    if (page != _visiblePage) setState(() => _visiblePage = page);
  }

  Future<void> _open() async {
    setState(() {
      _loading = true;
      _error = null;
      _nativeNote = 'Loading PDF bytes + opening with pdfrx PDFium…';
    });
    final Stopwatch watch = Stopwatch()..start();
    try {
      final ByteData data =
          await rootBundle.load(Phase12TransparencyScreen.assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      if (bytes.length != Phase12TransparencyScreen.expectedBytes) {
        throw StateError(
          'PDF size ${bytes.length} != ${Phase12TransparencyScreen.expectedBytes}',
        );
      }
      final PdfDocument document = await PdfDocument.openData(
        bytes,
        sourceName: 'phase2-all-33-transparent.pdf',
      );
      watch.stop();
      if (document.pages.length != Phase12TransparencyScreen.expectedPages) {
        await document.dispose();
        throw StateError(
          'page count ${document.pages.length} != 33',
        );
      }
      debugPrint(
        '[phase21] opened pages=${document.pages.length} '
        'loadMs=${watch.elapsedMilliseconds} bytes=${bytes.length}',
      );
      if (!mounted) {
        await document.dispose();
        return;
      }
      setState(() {
        _document = document;
        _loadMs = watch.elapsedMilliseconds;
        _loading = false;
        _nativeNote =
            'pdfrx 1.0.84 PDFium OK — 33 pages, soft-mask bg=transparent, lazy render';
      });
    } catch (error, stack) {
      watch.stop();
      debugPrint('[phase21] ERROR $error\n$stack');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
        _nativeNote = 'PDFium open FAILED: $error';
      });
    }
  }

  double _pageWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width - 24;

  double _blockHeight(int index, double pageWidth) {
    final PdfPage page = _document!.pages[index];
    final double height = pageWidth * (page.height / page.width);
    return _labelHeight + _labelGap + height;
  }

  double _offsetFor(int index, double pageWidth) {
    double y = 0;
    for (int i = 0; i < index; i++) {
      y += _blockHeight(i, pageWidth) + _pageGap;
    }
    return y;
  }

  int _pageAt(double offset, double pageWidth) {
    double y = 0;
    for (int i = 0; i < _document!.pages.length; i++) {
      final double next = y + _blockHeight(i, pageWidth) + _pageGap;
      if (offset < next - 8) return i + 1;
      y = next;
    }
    return _document!.pages.length;
  }

  void _setZoom(double factor) {
    setState(() => _zoom = factor);
  }

  void _jumpToPage(int pageNumber) {
    if (_document == null || !_scroll.hasClients) return;
    final int index = pageNumber - 1;
    if (index < 0 || index >= _document!.pages.length) return;
    final double width = _pageWidth(context);
    final double target = _offsetFor(index, width);
    final double max = _scroll.position.maxScrollExtent;
    _scroll.jumpTo(target.clamp(0, max));
    setState(() => _visiblePage = pageNumber);
  }

  void _noteRender(int pageNumber, int ms) {
    _renderMs[pageNumber] = ms;
    debugPrint('[phase21] page $pageNumber renderMs=$ms');
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Phase 2.1 Transparency'),
        actions: [
          IconButton(
            tooltip: 'zoom-100',
            onPressed: () => _setZoom(1),
            icon: const Icon(Icons.looks_one),
          ),
          IconButton(
            tooltip: 'zoom-200',
            onPressed: () => _setZoom(2),
            icon: const Icon(Icons.looks_two),
          ),
          IconButton(
            tooltip: 'zoom-400',
            onPressed: () => _setZoom(4),
            icon: const Icon(Icons.looks_4),
          ),
        ],
      ),
      body: Column(
        children: [
          _BgSelector(
            value: _bg,
            onChanged: (_BgMode mode) => setState(() => _bg = mode),
          ),
          if (!_loading && _error == null) ...[
            _FocusJumpBar(onJump: _jumpToPage),
            _PageJumpBar(onJump: _jumpToPage),
            if (_pageHint() != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Text(
                  _pageHint()!,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFFE6DAC2)),
                ),
              ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              _statusLine(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFFE6DAC2)),
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  String? _pageHint() {
    switch (_visiblePage) {
      case 7:
        return 'Original page 7. The dense chart is the corrected 9×9 Yantra. Scroll within the page to see all 81 cells.';
      case 16:
        return 'Original page 16. The upper irregular chart stays opaque. The lower 4×4 chart is transparent around the diagram, with its cells kept.';
      default:
        return null;
    }
  }

  String _statusLine() {
    if (_loading || _error != null) return _nativeNote;
    final int? ms = _renderMs[_visiblePage];
    final String timing = ms == null ? 'not rendered yet' : '${ms}ms';
    return '$_nativeNote | open=${_loadMs}ms | view=p$_visiblePage '
        'render=$timing | rendered=${_renderMs.length}/33 | '
        'zoom=${_zoom.toStringAsFixed(1)}x | bg=$_bg';
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final double pageWidth = _pageWidth(context);
    return ListView.separated(
      controller: _scroll,
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.only(bottom: 48),
      cacheExtent: 400,
      itemCount: _document!.pages.length,
      separatorBuilder: (_, __) => const SizedBox(height: _pageGap),
      itemBuilder: (BuildContext context, int index) {
        final int pageNumber = index + 1;
        final PdfPage page = _document!.pages[index];
        final double height = pageWidth * (page.height / page.width);
        return _LazyPage(
          key: ValueKey<int>(pageNumber),
          document: _document!,
          gate: _renderGate,
          pageNumber: pageNumber,
          pageWidth: pageWidth,
          pageHeight: height,
          background: _bg,
          zoom: _zoom,
          dpiScale: _dpiScale,
          onRendered: _noteRender,
        );
      },
    );
  }
}

class _FocusJumpBar extends StatelessWidget {
  const _FocusJumpBar({required this.onJump});

  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: Phase12TransparencyScreen.focusPages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (BuildContext context, int index) {
          final int page = Phase12TransparencyScreen.focusPages[index];
          return ActionChip(
            tooltip: 'jump-page-$page',
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            label: Text('Page $page'),
            onPressed: () => onJump(page),
          );
        },
      ),
    );
  }
}

class _PageJumpBar extends StatelessWidget {
  const _PageJumpBar({required this.onJump});

  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: Phase12TransparencyScreen.expectedPages,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (BuildContext context, int index) {
          final int page = index + 1;
          final bool focus =
              Phase12TransparencyScreen.focusPages.contains(page);
          return ActionChip(
            tooltip: 'jump-page-$page',
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            label: Text('$page'),
            backgroundColor: focus ? const Color(0xFF5C4318) : null,
            onPressed: () => onJump(page),
          );
        },
      ),
    );
  }
}

class _BgSelector extends StatelessWidget {
  const _BgSelector({required this.value, required this.onChanged});

  final _BgMode value;
  final ValueChanged<_BgMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: SegmentedButton<_BgMode>(
        segments: const <ButtonSegment<_BgMode>>[
          ButtonSegment<_BgMode>(
            value: _BgMode.white,
            label: Text('White'),
            icon: Icon(Icons.crop_square),
            tooltip: 'bg-white',
          ),
          ButtonSegment<_BgMode>(
            value: _BgMode.checkerboard,
            label: Text('Checker'),
            icon: Icon(Icons.grid_on),
            tooltip: 'bg-checker',
          ),
          ButtonSegment<_BgMode>(
            value: _BgMode.parchment,
            label: Text('Olaichuvadi'),
            icon: Icon(Icons.auto_stories),
            tooltip: 'bg-parchment',
          ),
        ],
        selected: <_BgMode>{value},
        onSelectionChanged: (Set<_BgMode> next) => onChanged(next.first),
      ),
    );
  }
}

class _LazyPage extends StatefulWidget {
  const _LazyPage({
    super.key,
    required this.document,
    required this.gate,
    required this.pageNumber,
    required this.pageWidth,
    required this.pageHeight,
    required this.background,
    required this.zoom,
    required this.dpiScale,
    required this.onRendered,
  });

  final PdfDocument document;
  final Phase21RenderGate gate;
  final int pageNumber;
  final double pageWidth;
  final double pageHeight;
  final _BgMode background;
  final double zoom;
  final double dpiScale;
  final void Function(int pageNumber, int ms) onRendered;

  @override
  State<_LazyPage> createState() => _LazyPageState();
}

class _LazyPageState extends State<_LazyPage> {
  final TransformationController _zoomController = TransformationController();
  ui.Image? _image;
  bool _closed = false;
  int _generation = 0;
  double _localScale = 1;
  PdfPageRenderCancellationToken? _cancel;

  @override
  void initState() {
    super.initState();
    _zoomController.addListener(_onLocalZoom);
    _applyZoom(widget.zoom);
    _startRender();
  }

  @override
  void didUpdateWidget(covariant _LazyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zoom != widget.zoom) {
      _applyZoom(widget.zoom);
    }
    if (oldWidget.pageNumber != widget.pageNumber) {
      _releaseImage();
      _startRender();
    }
  }

  @override
  void dispose() {
    _closed = true;
    _generation++;
    _cancel?.cancel();
    _zoomController.removeListener(_onLocalZoom);
    _releaseImage();
    _zoomController.dispose();
    super.dispose();
  }

  void _onLocalZoom() {
    final double scale = _zoomController.value.getMaxScaleOnAxis();
    if (!mounted || (scale - _localScale).abs() < 0.01) return;
    setState(() => _localScale = scale);
  }

  void _applyZoom(double zoom) {
    _localScale = zoom;
    _zoomController.value = Matrix4.identity()..scale(zoom);
  }

  void _releaseImage() {
    final ui.Image? previous = _image;
    _image = null;
    previous?.dispose();
  }

  bool _owns(int pageNumber, int generation) {
    return phase21ResultIsCurrent(
      requestedPage: pageNumber,
      requestedGeneration: generation,
      currentPage: widget.pageNumber,
      currentGeneration: _generation,
      closed: _closed,
    );
  }

  void _startRender() {
    final int generation = ++_generation;
    final int pageNumber = widget.pageNumber;
    _cancel?.cancel();
    widget.gate.schedule(() => _render(pageNumber, generation));
  }

  Future<void> _render(int pageNumber, int generation) async {
    if (!_owns(pageNumber, generation)) return;
    final Stopwatch watch = Stopwatch()..start();
    PdfImage? pdfImage;
    try {
      final PdfPage page = widget.document.pages[pageNumber - 1];
      final PdfPageRenderCancellationToken token =
          page.createCancellationToken();
      _cancel = token;
      pdfImage = await page.render(
        fullWidth: page.width * widget.dpiScale,
        fullHeight: page.height * widget.dpiScale,
        backgroundColor: Colors.transparent,
        cancellationToken: token,
      );
      if (pdfImage == null || !_owns(pageNumber, generation)) {
        pdfImage?.dispose();
        pdfImage = null;
        return;
      }
      // Copy the native buffer before decode. createImage reads that buffer
      // asynchronously, and the next page must not share it.
      final Uint8List pixels = Uint8List.fromList(pdfImage.pixels);
      final int width = pdfImage.width;
      final int height = pdfImage.height;
      final ui.PixelFormat format = pdfImage.format;
      pdfImage.dispose();
      pdfImage = null;
      if (!_owns(pageNumber, generation)) return;
      final ui.Image image = await _decode(pixels, width, height, format);
      watch.stop();
      if (!mounted || !_owns(pageNumber, generation)) {
        image.dispose();
        return;
      }
      _releaseImage();
      setState(() => _image = image);
      widget.onRendered(pageNumber, watch.elapsedMilliseconds);
    } catch (error, stack) {
      debugPrint('[phase21] page $pageNumber render error $error\n$stack');
    } finally {
      pdfImage?.dispose();
    }
  }

  Future<ui.Image> _decode(
    Uint8List pixels,
    int width,
    int height,
    ui.PixelFormat format,
  ) {
    final Completer<ui.Image> completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      format,
      completer.complete,
    );
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final bool zoomed = _localScale > 1.01;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _Phase12TransparencyScreenState._labelHeight,
            child: Text(
              'Original page ${widget.pageNumber}'
              '${_image == null ? '' : '  ·  ${_image!.width}×${_image!.height}'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFE6DAC2), fontSize: 12),
            ),
          ),
          const SizedBox(height: _Phase12TransparencyScreenState._labelGap),
          SizedBox(
            width: widget.pageWidth,
            height: widget.pageHeight,
            child: ClipRect(
              child: InteractiveViewer(
                transformationController: _zoomController,
                minScale: 1,
                maxScale: 4,
                panEnabled: zoomed,
                scaleEnabled: true,
                clipBehavior: Clip.hardEdge,
                boundaryMargin: EdgeInsets.zero,
                child: SizedBox(
                  width: widget.pageWidth,
                  height: widget.pageHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(child: _backgroundLayer()),
                      if (_image == null)
                        const Center(child: CircularProgressIndicator())
                      else
                        RawImage(
                          image: _image,
                          fit: BoxFit.fill,
                          filterQuality: FilterQuality.medium,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundLayer() {
    switch (widget.background) {
      case _BgMode.white:
        return const ColoredBox(color: Colors.white);
      case _BgMode.checkerboard:
        return const CustomPaint(painter: _CheckerPainter());
      case _BgMode.parchment:
        return ReaderSurface(
          palette: ReaderPalette.of(ReaderThemeMode.olaichuvadi),
          fadeContent: false,
          child: const SizedBox.expand(),
        );
    }
  }
}

class _CheckerPainter extends CustomPainter {
  const _CheckerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const double cell = 16;
    final Paint light = Paint()..color = const Color(0xFFE8E8E8);
    final Paint dark = Paint()..color = const Color(0xFFB0B0B0);
    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        final bool odd = (((x / cell).floor() + (y / cell).floor()) & 1) == 1;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cell, cell),
          odd ? dark : light,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
