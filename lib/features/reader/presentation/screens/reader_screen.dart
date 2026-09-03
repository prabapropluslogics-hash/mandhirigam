import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../routing/app_router.dart';
import '../../../../shared/data/mock_catalog.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/models/reading_prefs.dart';
import '../widgets/highlight_toolbar.dart';
import '../widgets/reader_body_text.dart';
import '../widgets/reader_customize_sheet.dart';
import '../widgets/reader_progress_footer.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.bookId});

  final String bookId;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final Book _book = MockCatalog.byId(widget.bookId);
  late int _chapterIndex =
      (_book.currentChapter > 0 ? _book.currentChapter - 1 : 0)
          .clamp(0, _book.totalChapters - 1);
  ReadingPrefs _prefs = const ReadingPrefs();
  bool _bookmarked = false;
  bool _showToolbar = true;
  Color _highlightColor = AppColors.highlightYellow;

  bool get _isAmberRoom =>
      _book.id == MockCatalog.quietHours.id && _chapterIndex == 11;

  Color get _pageColor => switch (_prefs.mode) {
        ReadingMode.light => AppColors.background,
        ReadingMode.sepia => AppColors.readingSepia,
        ReadingMode.dark => AppColors.backgroundDark,
      };

  Color get _inkColor => switch (_prefs.mode) {
        ReadingMode.light => AppColors.textPrimary,
        ReadingMode.sepia => AppColors.readingSepiaInk,
        ReadingMode.dark => AppColors.textPrimaryDark,
      };

  Color get _mutedColor => switch (_prefs.mode) {
        ReadingMode.light => AppColors.textSecondary,
        ReadingMode.sepia => AppColors.readingSepiaInk.withOpacity(0.7),
        ReadingMode.dark => AppColors.textSecondaryDark,
      };

  Color get _trackColor => switch (_prefs.mode) {
        ReadingMode.dark => AppColors.surfaceMutedDark,
        ReadingMode.sepia => AppColors.brandSecondary.withOpacity(0.2),
        ReadingMode.light => AppColors.neutral100,
      };

  String get _chapterTitle {
    if (_chapterIndex < _book.chapters.length) {
      return _book.chapters[_chapterIndex];
    }
    return 'Chapter ${_chapterIndex + 1}';
  }

  Future<void> _openCustomize() {
    return showReaderCustomizeSheet(
      context,
      initial: _prefs,
      onChanged: (ReadingPrefs next) => setState(() => _prefs = next),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool lightIcons = _prefs.mode == ReadingMode.dark;
    final double dim = (1 - _prefs.brightness).clamp(0.0, 0.55);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: lightIcons
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: AppScaffold(
        backgroundColor: _pageColor,
        safeAreaBottom: false,
        body: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: AppInsets.pageHorizontal,
                  child: Row(
                    children: [
                      AppIconButton(
                        icon: AppIcons.back,
                        tooltip: 'Back',
                        color: _inkColor,
                        onPressed: () => AppRouter.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'CHAPTER ${_chapterIndex + 1}',
                              style: AppTypography.caption(context).copyWith(
                                color: _mutedColor,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _chapterTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bookTitle(
                                context,
                                fontSize: 16,
                                color: _inkColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppIconButton(
                        icon: _bookmarked
                            ? AppIcons.bookmarkFilled
                            : AppIcons.bookmark,
                        tooltip: 'Bookmark',
                        color: _inkColor,
                        onPressed: () =>
                            setState(() => _bookmarked = !_bookmarked),
                      ),
                      AppIconButton(
                        icon: AppIcons.filters,
                        tooltip: 'Reading settings',
                        color: _inkColor,
                        onPressed: _openCustomize,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showToolbar = false),
                    child: ListView(
                      padding: AppInsets.page,
                      children: [
                        if (_isAmberRoom && _showToolbar) ...[
                          Center(
                            child: HighlightToolbar(
                              selectedColor: _highlightColor,
                              onColorSelected: (Color color) {
                                setState(() => _highlightColor = color);
                              },
                            ),
                          ),
                          const AppGap.md(),
                        ],
                        if (_isAmberRoom)
                          ReaderBodyText(
                            lead: MockCatalog.readerLead,
                            highlight: MockCatalog.readerHighlight,
                            rest: MockCatalog.readerRest,
                            prefs: _prefs,
                            textColor: _inkColor,
                            highlightColor: _highlightColor,
                            showDropCap: true,
                            onHighlightTap: () {
                              setState(() => _showToolbar = !_showToolbar);
                            },
                          )
                        else
                          Text(
                            MockCatalog.chapterBody(_book, _chapterIndex),
                            style: AppTypography.readingBody(
                              color: _inkColor,
                              fontSize: _prefs.fontSize,
                              height: _prefs.lineHeight,
                              fontStyle: _prefs.typefaceId == 'fraunces'
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                          ),
                        const AppGap.xxxl(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: AppInsets.page,
                  child: SafeArea(
                    top: false,
                    child: ReaderProgressFooter(
                      book: _book,
                      chapterIndex: _chapterIndex,
                      progress: MockCatalog.quietHoursReaderProgress,
                      textColor: _mutedColor,
                      trackColor: _trackColor,
                      onPrevious: _chapterIndex == 0
                          ? null
                          : () => setState(() {
                                _chapterIndex -= 1;
                                _showToolbar = _isAmberRoom;
                              }),
                      onNext: _chapterIndex >= _book.totalChapters - 1
                          ? null
                          : () => setState(() {
                                _chapterIndex += 1;
                                _showToolbar = false;
                              }),
                    ),
                  ),
                ),
              ],
            ),
            if (dim > 0)
              IgnorePointer(
                child: ColoredBox(
                  color: AppColors.shadow.withOpacity(dim),
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
