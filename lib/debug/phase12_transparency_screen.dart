import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';

import '../features/reader/presentation/reader_palette.dart';
import '../features/reader/presentation/widgets/reader_paper.dart';
import '../features/reader/state/reader_preferences.dart';

/// Debug-only screen: Phase 1.1 five-page transparent PDF over selectable
/// Flutter backgrounds using production `pdfrx` 1.0.84 PDFium.
///
/// Uses [PdfPage.render] with [Colors.transparent] so soft-mask alpha can
/// composite onto the Flutter widget behind the page. Production
/// [PdfViewer] currently hardcodes a white page fill and is therefore not
/// used here for parchment compositing verification.
class Phase12TransparencyScreen extends StatefulWidget {
  const Phase12TransparencyScreen({super.key});

  static const String assetPath =
      'assets/debug/phase1_1-five-pages-transparent.pdf';

  /// Transparent-PDF page index → original source page number.
  static const List<int> originalPageNumbers = <int>[1, 7, 25, 33, 13];

  @override
  State<Phase12TransparencyScreen> createState() =>
      _Phase12TransparencyScreenState();
}

enum _BgMode { white, checkerboard, parchment }

class _Phase12TransparencyScreenState extends State<Phase12TransparencyScreen> {
  final TransformationController _transform = TransformationController();
  final Stopwatch _loadWatch = Stopwatch();

  /// Cumulative Y offsets (logical px at 100% zoom) for jump-to-page.
  final List<double> _pageTopY = <double>[];

  PdfDocument? _document;
  final List<ui.Image?> _pages = <ui.Image?>[];
  final List<int> _pageRenderMs = <int>[];

  _BgMode _bg = _BgMode.parchment;
  bool _loading = true;
  String? _error;
  String _nativeNote = 'pdfrx 1.0.84 / waiting for Android PDFium load';
  int _loadMs = 0;
  double _zoom = 1;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    for (final ui.Image? image in _pages) {
      image?.dispose();
    }
    _document?.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _recomputePageTops(double pageWidth) {
    _pageTopY
      ..clear()
      ..add(0);
    double y = 0;
    for (int i = 0; i < _pages.length; i++) {
      final ui.Image image = _pages[i]!;
      // Label (~18) + gap (6) + page height + inter-page gap (18 except last).
      const double labelBlock = 24;
      final double pageHeight = pageWidth * (image.height / image.width);
      y += labelBlock + pageHeight;
      if (i < _pages.length - 1) y += 18;
      if (i + 1 < _pages.length) _pageTopY.add(y);
    }
  }

  Future<void> _open() async {
    setState(() {
      _loading = true;
      _error = null;
      _nativeNote = 'Loading PDF bytes + opening with pdfrx PDFium…';
    });
    _loadWatch
      ..reset()
      ..start();
    try {
      final ByteData data =
          await rootBundle.load(Phase12TransparencyScreen.assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final PdfDocument document = await PdfDocument.openData(
        bytes,
        sourceName: 'phase1_1-five-pages-transparent.pdf',
      );
      _loadWatch.stop();
      _loadMs = _loadWatch.elapsedMilliseconds;
      debugPrint(
        '[phase12] opened pages=${document.pages.length} loadMs=$_loadMs '
        'bytes=${bytes.length}',
      );

      final List<ui.Image?> rendered =
          List<ui.Image?>.filled(document.pages.length, null);
      final List<int> timings = List<int>.filled(document.pages.length, 0);

      // ~150 DPI for readable on-device inspection without extreme memory.
      const double dpiScale = 150 / 72;
      for (int i = 0; i < document.pages.length; i++) {
        final Stopwatch pageWatch = Stopwatch()..start();
        final PdfPage page = document.pages[i];
        final double fullWidth = page.width * dpiScale;
        final double fullHeight = page.height * dpiScale;
        final PdfImage? pdfImage = await page.render(
          fullWidth: fullWidth,
          fullHeight: fullHeight,
          // Critical: transparent fill so soft-mask regions keep alpha=0 and
          // composite onto the Flutter background behind the page Image.
          backgroundColor: Colors.transparent,
        );
        if (pdfImage == null) {
          throw StateError('PdfPage.render returned null for page ${i + 1}');
        }
        final ui.Image image = await pdfImage.createImage();
        pdfImage.dispose();
        pageWatch.stop();
        rendered[i] = image;
        timings[i] = pageWatch.elapsedMilliseconds;
        debugPrint(
          '[phase12] page ${i + 1} (orig '
          '${Phase12TransparencyScreen.originalPageNumbers[i]}) '
          '${image.width}x${image.height} renderMs=${timings[i]} '
          'pixels=bgra8888',
        );
      }

      if (!mounted) {
        for (final ui.Image? image in rendered) {
          image?.dispose();
        }
        await document.dispose();
        return;
      }

      setState(() {
        _document = document;
        _pages
          ..clear()
          ..addAll(rendered);
        _pageRenderMs
          ..clear()
          ..addAll(timings);
        _loading = false;
        _nativeNote =
            'pdfrx 1.0.84 Android/desktop PDFium OK — '
            '${document.pages.length} pages, soft-mask render bg=transparent';
      });
    } catch (error, stack) {
      _loadWatch.stop();
      debugPrint('[phase12] ERROR $error\n$stack');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
        _nativeNote = 'PDFium open/render FAILED: $error';
      });
    }
  }

  void _setZoom(double factor, {int? keepPageIndex}) {
    final int page = keepPageIndex ?? 0;
    final double top =
        page < _pageTopY.length ? _pageTopY[page] : 0;
    final Matrix4 next = Matrix4.identity()
      ..scale(factor)
      ..translate(0.0, -top);
    _transform.value = next;
    setState(() => _zoom = factor);
  }

  void _jumpToPage(int index) {
    if (index < 0 || index >= _pageTopY.length) return;
    final double top = _pageTopY[index];
    final Matrix4 next = Matrix4.identity()
      ..scale(_zoom)
      ..translate(0.0, -top);
    _transform.value = next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Phase 1.2 Transparency'),
        actions: [
          IconButton(
            tooltip: '100%',
            onPressed: () => _setZoom(1),
            icon: const Icon(Icons.looks_one),
          ),
          IconButton(
            tooltip: '200%',
            onPressed: () => _setZoom(2, keepPageIndex: 1),
            icon: const Icon(Icons.looks_two),
          ),
          IconButton(
            tooltip: '400%',
            onPressed: () => _setZoom(4, keepPageIndex: 1),
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
          if (!_loading && _error == null) _PageJumpBar(onJump: _jumpToPage),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              _statusLine(),
              style: const TextStyle(fontSize: 12, color: Color(0xFFE6DAC2)),
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  String _statusLine() {
    if (_loading) return _nativeNote;
    if (_error != null) return _nativeNote;
    final String timings = _pageRenderMs
        .asMap()
        .entries
        .map((MapEntry<int, int> e) => 'p${e.key + 1}:${e.value}ms')
        .join(' ');
    return '$_nativeNote | open=${_loadMs}ms | $timings | zoom=${_zoom.toStringAsFixed(1)}x | bg=$_bg';
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

    final double viewportWidth = MediaQuery.sizeOf(context).width;
    final double pageWidth = viewportWidth - 24;
    _recomputePageTops(pageWidth);

    // constrained: false is required so the tall multi-page Column is not
    // forced into the viewport height (that caused BOTTOM OVERFLOWED BY ~2k px).
    // Pan vertically to reach every page; use jump chips / zoom buttons for QA.
    return InteractiveViewer(
      transformationController: _transform,
      constrained: false,
      minScale: 0.5,
      maxScale: 5,
      boundaryMargin: const EdgeInsets.all(400),
      child: SizedBox(
        width: viewportWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < _pages.length; i++) ...[
              if (i > 0) const SizedBox(height: 18),
              _PageCard(
                pageIndex: i,
                originalPage:
                    Phase12TransparencyScreen.originalPageNumbers[i],
                image: _pages[i]!,
                background: _bg,
                pageWidth: pageWidth,
              ),
            ],
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _PageJumpBar extends StatelessWidget {
  const _PageJumpBar({required this.onJump});

  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          for (int i = 0;
              i < Phase12TransparencyScreen.originalPageNumbers.length;
              i++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ActionChip(
                label: Text(
                  'P${i + 1}→${Phase12TransparencyScreen.originalPageNumbers[i]}',
                ),
                onPressed: () => onJump(i),
              ),
            ),
        ],
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
          ),
          ButtonSegment<_BgMode>(
            value: _BgMode.checkerboard,
            label: Text('Checker'),
            icon: Icon(Icons.grid_on),
          ),
          ButtonSegment<_BgMode>(
            value: _BgMode.parchment,
            label: Text('Olaichuvadi'),
            icon: Icon(Icons.auto_stories),
          ),
        ],
        selected: <_BgMode>{value},
        onSelectionChanged: (Set<_BgMode> next) => onChanged(next.first),
      ),
    );
  }
}

class _PageCard extends StatelessWidget {
  const _PageCard({
    required this.pageIndex,
    required this.originalPage,
    required this.image,
    required this.background,
    required this.pageWidth,
  });

  final int pageIndex;
  final int originalPage;
  final ui.Image image;
  final _BgMode background;
  final double pageWidth;

  @override
  Widget build(BuildContext context) {
    final double height = pageWidth * (image.height / image.width);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PDF page ${pageIndex + 1}  ·  original page $originalPage  ·  '
            '${image.width}×${image.height}',
            style: const TextStyle(color: Color(0xFFE6DAC2), fontSize: 12),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: pageWidth,
            height: height,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(child: _backgroundLayer()),
                  // Soft-mask page: transparent pixels reveal Flutter bg.
                  RawImage(
                    image: image,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backgroundLayer() {
    switch (background) {
      case _BgMode.white:
        return const ColoredBox(color: Colors.white);
      case _BgMode.checkerboard:
        return const CustomPaint(painter: _CheckerPainter());
      case _BgMode.parchment:
        // Reuse production Olaichuvadi parchment surface (no edge fade).
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
