import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/reader/presentation/reader_palette.dart';
import '../features/reader/presentation/widgets/reader_paper.dart';
import '../features/reader/state/reader_preferences.dart';
import 'phase23_png_catalog.dart';
import 'phase23_png_pages.dart';

/// Debug-only reader for the 33 Phase 2 transparent PNGs.
///
/// Page pixels come from `assets/debug/phase2_png/page_XX.png`, which are
/// copies of `packed.png`. PDFium is not opened and no page is rendered
/// from a PDF. Remove this screen, the PNG assets, and the pubspec entry
/// after QA.
class Phase12TransparencyScreen extends StatefulWidget {
  const Phase12TransparencyScreen({super.key});

  static const int expectedPages = Phase23Pages.pageCount;

  /// Pages called out for close inspection. Order matches the source PDF.
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
  static const double _controlCanvasHeight = 180;

  final ScrollController _scroll = ScrollController();
  late final Phase23LoadCoordinator<ui.Image> _pages =
      Phase23LoadCoordinator<ui.Image>(
    maxReady: 5,
    decode: _decodePage,
    release: (ui.Image image) {
      WidgetsBinding.instance.addPostFrameCallback((_) => image.dispose());
    },
    onChanged: () {
      if (mounted) setState(() {});
    },
  );

  _BgMode _bg = _BgMode.parchment;
  double _zoom = 1;
  int _visiblePage = 1;

  double get _controlSlot => _labelHeight + _labelGap + _controlCanvasHeight;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _pages.close();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final int page = _pageAt(_scroll.offset, _pageWidth(context));
    if (page == _visiblePage) return;
    _pages.setVisible(page);
    setState(() => _visiblePage = page);
  }

  Future<ui.Image> _decodePage(int page) async {
    final ByteData data = await rootBundle.load(Phase23Pages.assetFor(page));
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    try {
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ui.Image image = frame.image;
      if (image.width != Phase23Pages.width ||
          image.height != Phase23Pages.height) {
        final int width = image.width;
        final int height = image.height;
        image.dispose();
        throw StateError('page $page decoded as ${width}x$height');
      }
      return image;
    } finally {
      codec.dispose();
    }
  }

  double _pageWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width - 24;

  double _pageHeight(double pageWidth) =>
      pageWidth * (Phase23Pages.height / Phase23Pages.width);

  double _blockHeight(double pageWidth) =>
      _labelHeight + _labelGap + _pageHeight(pageWidth);

  double _offsetFor(int pageNumber, double pageWidth) {
    double y = _controlSlot + _pageGap;
    for (int page = 1; page < pageNumber; page++) {
      y += _blockHeight(pageWidth) + _pageGap;
    }
    return y;
  }

  int _pageAt(double offset, double pageWidth) {
    double y = _controlSlot + _pageGap;
    if (offset < y - 8) return 1;
    for (int page = 1; page <= Phase23Pages.pageCount; page++) {
      final double next = y + _blockHeight(pageWidth) + _pageGap;
      if (offset < next - 8) return page;
      y = next;
    }
    return Phase23Pages.pageCount;
  }

  void _setZoom(double factor) {
    setState(() => _zoom = factor);
  }

  void _jumpToPage(int pageNumber) {
    if (!_scroll.hasClients) return;
    if (pageNumber < 1 || pageNumber > Phase23Pages.pageCount) return;
    final double width = _pageWidth(context);
    final double target = _offsetFor(pageNumber, width);
    final double max = _scroll.position.maxScrollExtent;
    _scroll.jumpTo(target.clamp(0, max));
    _pages.setVisible(pageNumber);
    setState(() => _visiblePage = pageNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Phase 2.3 PNG pages'),
        actions: <Widget>[
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
        children: <Widget>[
          _BgSelector(
            value: _bg,
            onChanged: (_BgMode mode) => setState(() => _bg = mode),
          ),
          _FocusJumpBar(onJump: _jumpToPage),
          _PageJumpBar(onJump: _jumpToPage),
          if (_pageHint() != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Text(
                _pageHint()!,
                style: const TextStyle(fontSize: 12, color: Color(0xFFE6DAC2)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              _statusLine(),
              maxLines: 4,
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
    return 'PNG IMAGE MODE — PDFium disabled — 33 pages | '
        'view=p$_visiblePage | decoded=${_pages.decodedCount} | '
        'cached=${_pages.cachedCount} | assets=${Phase23Pages.totalBytes} bytes | '
        'zoom=${_zoom.toStringAsFixed(1)}x | bg=$_bg';
  }

  Widget _body() {
    final double pageWidth = _pageWidth(context);
    final double pageHeight = _pageHeight(pageWidth);
    return ListView.separated(
      controller: _scroll,
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.only(bottom: 48),
      cacheExtent: 720,
      itemCount: Phase23Pages.pageCount + 1,
      separatorBuilder: (_, __) => const SizedBox(height: _pageGap),
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return _StaticControlPage(
            pageWidth: pageWidth,
            canvasHeight: _controlCanvasHeight,
            zoom: _zoom,
          );
        }
        final int pageNumber = index;
        return _PngPage(
          key: ValueKey<String>('${Phase23Pages.fingerprint}-$pageNumber'),
          store: _pages,
          pageNumber: pageNumber,
          pageWidth: pageWidth,
          pageHeight: pageHeight,
          background: _bg,
          zoom: _zoom,
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
        itemCount: Phase23Pages.pageCount,
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

class _PngPage extends StatefulWidget {
  const _PngPage({
    super.key,
    required this.store,
    required this.pageNumber,
    required this.pageWidth,
    required this.pageHeight,
    required this.background,
    required this.zoom,
  });

  final Phase23LoadCoordinator<ui.Image> store;
  final int pageNumber;
  final double pageWidth;
  final double pageHeight;
  final _BgMode background;
  final double zoom;

  @override
  State<_PngPage> createState() => _PngPageState();
}

class _PngPageState extends State<_PngPage> {
  final TransformationController _zoomController = TransformationController();
  double _localScale = 1;

  @override
  void initState() {
    super.initState();
    _zoomController.addListener(_onLocalZoom);
    _applyZoom(widget.zoom);
    widget.store.pin(widget.pageNumber);
  }

  @override
  void didUpdateWidget(covariant _PngPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zoom != widget.zoom) _applyZoom(widget.zoom);
    if (oldWidget.pageNumber != widget.pageNumber) {
      oldWidget.store.unpin(oldWidget.pageNumber);
      widget.store.pin(widget.pageNumber);
    }
  }

  @override
  void dispose() {
    widget.store.unpin(widget.pageNumber);
    _zoomController.removeListener(_onLocalZoom);
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

  @override
  Widget build(BuildContext context) {
    final ui.Image? image = widget.store.readyFor(widget.pageNumber);
    final bool zoomed = _localScale > 1.01;
    final Object? error = widget.store.errorFor(widget.pageNumber);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: _Phase12TransparencyScreenState._labelHeight,
            child: Text(
              'Original page ${widget.pageNumber}'
              '${image == null ? '' : '  ·  ${image.width}×${image.height}'}',
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
                    children: <Widget>[
                      Positioned.fill(child: _backgroundLayer()),
                      if (image == null && error != null)
                        Center(
                          child: Text(
                            '$error',
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else if (image == null)
                        const Center(child: CircularProgressIndicator())
                      else
                        RawImage(
                          image: image,
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

class _StaticControlPage extends StatefulWidget {
  const _StaticControlPage({
    required this.pageWidth,
    required this.canvasHeight,
    required this.zoom,
  });

  final double pageWidth;
  final double canvasHeight;
  final double zoom;

  @override
  State<_StaticControlPage> createState() => _StaticControlPageState();
}

class _StaticControlPageState extends State<_StaticControlPage> {
  final TransformationController _zoomController = TransformationController();

  @override
  void initState() {
    super.initState();
    _applyZoom(widget.zoom);
  }

  @override
  void didUpdateWidget(covariant _StaticControlPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zoom != widget.zoom) _applyZoom(widget.zoom);
  }

  @override
  void dispose() {
    _zoomController.dispose();
    super.dispose();
  }

  void _applyZoom(double zoom) {
    _zoomController.value = Matrix4.identity()..scale(zoom);
  }

  @override
  Widget build(BuildContext context) {
    final bool zoomed = widget.zoom > 1.01;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            height: _Phase12TransparencyScreenState._labelHeight,
            child: Text(
              'Static control — not from PDFium',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Color(0xFFE6DAC2), fontSize: 12),
            ),
          ),
          const SizedBox(height: _Phase12TransparencyScreenState._labelGap),
          SizedBox(
            width: widget.pageWidth,
            height: widget.canvasHeight,
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
                  height: widget.canvasHeight,
                  child: const CustomPaint(painter: _ControlPainter()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlPainter extends CustomPainter {
  const _ControlPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF123C6B),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2),
      Paint()..color = const Color(0xFFC4551D),
    );
    canvas.drawLine(
      Offset.zero,
      Offset(size.width, size.height),
      Paint()
        ..color = const Color(0xFFFFE08A)
        ..strokeWidth = 4,
    );
    final TextPainter label = TextPainter(
      text: const TextSpan(
        text: 'STATIC CONTROL',
        style: TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, const Offset(16, 16));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
