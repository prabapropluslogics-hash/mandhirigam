import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/models/rich_text_document.dart';
import '../../design_system/theme/app_colors.dart';
import '../../design_system/theme/app_spacing.dart';
import '../../design_system/theme/app_typography.dart';
import '../../features/reader/presentation/reader_palette.dart';
import '../../features/reader/presentation/widgets/reader_paper.dart';
import '../../features/reader/presentation/widgets/rich_text_document_view.dart';
import '../../features/reader/state/reader_preferences.dart';
import 'fixture_loader.dart';
import 'ocr_review_banner.dart';

/// Phase 03 demonstration that uses the **production** Rich Text V2 widgets
/// ([RichTextDocumentView], [ReaderSurface], [ReadingStyle]) with the Admin
/// handoff fixture. Not a second production renderer.
class Phase03ReflowableDemoScreen extends StatefulWidget {
  const Phase03ReflowableDemoScreen({
    super.key,
    this.fixturesDir,
    this.initialFontSize = 16,
    this.initialTheme = ReaderThemeMode.olaichuvadi,
    this.initialLineHeight = ReaderLineHeight.comfortable,
    this.initialScrollFraction = 0,
  });

  final Directory? fixturesDir;
  final double initialFontSize;
  final ReaderThemeMode initialTheme;
  final ReaderLineHeight initialLineHeight;
  final double initialScrollFraction;

  @override
  State<Phase03ReflowableDemoScreen> createState() =>
      _Phase03ReflowableDemoScreenState();
}

class _Phase03ReflowableDemoScreenState
    extends State<Phase03ReflowableDemoScreen> {
  final ScrollController _scroll = ScrollController();
  late double _fontSize = widget.initialFontSize;
  late ReaderThemeMode _theme = widget.initialTheme;
  late ReaderLineHeight _lineHeight = widget.initialLineHeight;
  late final ReflowableEbookFixture _fixture;
  double _restoredFraction = 0;
  bool _ready = false;
  String? _error;
  Timer? _progressDebounce;

  @override
  void initState() {
    super.initState();
    try {
      final Directory dir =
          widget.fixturesDir ?? resolveReflowableFixturesDir();
      _fixture = loadReflowableEbookFixture(fixturesDir: dir);
      installLocalFixtureImageProvider(_fixture.localAssetByMediaId);
      _restoredFraction = widget.initialScrollFraction.clamp(0.0, 1.0);
      _ready = true;
    } catch (error) {
      _error = '$error';
    }
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreScroll());
  }

  @override
  void dispose() {
    _progressDebounce?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    clearLocalFixtureImageProvider();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    _progressDebounce?.cancel();
    _progressDebounce = Timer(const Duration(milliseconds: 200), () {
      if (!_scroll.hasClients) return;
      final double max = _scroll.position.maxScrollExtent;
      _restoredFraction = max <= 0 ? 0 : (_scroll.offset / max).clamp(0.0, 1.0);
    });
  }

  void _restoreScroll() {
    if (!_scroll.hasClients) return;
    final double max = _scroll.position.maxScrollExtent;
    _scroll.jumpTo((_restoredFraction * max).clamp(0.0, max));
  }

  /// Exposed for widget tests verifying position restoration.
  double get scrollFraction {
    if (!_scroll.hasClients) return _restoredFraction;
    final double max = _scroll.position.maxScrollExtent;
    if (max <= 0) return 0;
    return (_scroll.offset / max).clamp(0.0, 1.0);
  }

  void restoreScrollFraction(double fraction) {
    setState(() => _restoredFraction = fraction.clamp(0.0, 1.0));
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreScroll());
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.readerChrome,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.neutral0),
            ),
          ),
        ),
      );
    }
    if (!_ready) {
      return const Scaffold(
        backgroundColor: AppColors.readerChrome,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final ReaderPalette palette = ReaderPalette.of(_theme);
    final ReadingStyle style = ReadingStyle(
      fontSize: _fontSize,
      lineHeight: _lineHeight.factor,
      textColor: palette.text,
      secondaryColor: palette.secondaryText,
      accentColor: palette.accent,
      fontFamily: AppTypography.serifFamily,
      fontFamilyFallback: AppTypography.serifFallbacks,
    );
    final RichTextDocument document = _fixture.chapter.content!;

    // Prefer InkRipple so debug screenshots / toImage are not broken by InkSparkle.
    return Theme(
      data: Theme.of(context).copyWith(splashFactory: InkRipple.splashFactory),
      child: Scaffold(
        backgroundColor: AppColors.readerChrome,
        appBar: AppBar(
          backgroundColor: AppColors.readerChrome,
          foregroundColor: AppColors.brandPrimary,
          title: Text(
            'Phase 03 · Rich Text V2 fixture',
            style: AppTypography.caption(context).copyWith(
              color: AppColors.brandPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: OcrReviewBanner(reviewNotes: _fixture.reviewNotes),
              ),
              _DemoControls(
                fontSize: _fontSize,
                theme: _theme,
                lineHeight: _lineHeight,
                onFontSize: (double value) => setState(() => _fontSize = value),
                onTheme: (ReaderThemeMode value) =>
                    setState(() => _theme = value),
                onLineHeight: (ReaderLineHeight value) =>
                    setState(() => _lineHeight = value),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm,
                    AppSpacing.xs,
                    AppSpacing.sm,
                    AppSpacing.sm,
                  ),
                  child: Theme(
                    data: palette.theme(),
                    child: ReaderSurface(
                      palette: palette,
                      fadeContent: true,
                      child: ListView(
                        key: const ValueKey<String>('phase03-reflow-list'),
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
                        children: [
                          Text(
                            _fixture.chapter.title,
                            style: AppTypography.bookTitle(
                              context,
                              fontSize: (_fontSize * 1.25).clamp(18.0, 32.0),
                              color: palette.text,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Production renderer — not a parallel demo renderer.
                          RichTextDocumentView(
                            document: document,
                            style: style,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoControls extends StatelessWidget {
  const _DemoControls({
    required this.fontSize,
    required this.theme,
    required this.lineHeight,
    required this.onFontSize,
    required this.onTheme,
    required this.onLineHeight,
  });

  final double fontSize;
  final ReaderThemeMode theme;
  final ReaderLineHeight lineHeight;
  final ValueChanged<double> onFontSize;
  final ValueChanged<ReaderThemeMode> onTheme;
  final ValueChanged<ReaderLineHeight> onLineHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final double size in <double>[16, 22, 28])
            ChoiceChip(
              key: ValueKey<String>('font-${size.toInt()}'),
              label: Text('${size.toInt()}'),
              selected: fontSize == size,
              onSelected: (_) => onFontSize(size),
            ),
          for (final ReaderThemeMode mode in ReaderThemeMode.values)
            ChoiceChip(
              key: ValueKey<String>('theme-${mode.code}'),
              label: Text(mode.label),
              selected: theme == mode,
              onSelected: (_) => onTheme(mode),
            ),
          for (final ReaderLineHeight height in ReaderLineHeight.values)
            ChoiceChip(
              key: ValueKey<String>('lh-${height.code}'),
              label: Text(height.label),
              selected: lineHeight == height,
              onSelected: (_) => onLineHeight(height),
            ),
        ],
      ),
    );
  }
}
