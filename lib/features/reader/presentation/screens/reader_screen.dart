import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/app_container.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/security/screen_security.dart';
import '../../../../data/models/catalog_book.dart';
import '../../../../data/models/chapter.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/feedback/app_empty_state.dart';
import '../../../../design_system/components/feedback/app_loader.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../routing/app_router.dart';
import '../../../../services/share_service.dart';
import '../../../auth/presentation/require_sign_in.dart';
import '../../../book_details/presentation/screens/book_details_screen.dart';
import '../../../payment/presentation/payment_flow.dart';
import '../../state/reader_preferences.dart';
import '../reader_palette.dart';
import '../widgets/reader_chapter_sheet.dart';
import '../widgets/reader_paper.dart';
import '../widgets/reader_settings_panel.dart';
import '../widgets/rich_text_document_view.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.args});

  final ReaderArgs args;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late String _chapterId = widget.args.chapterId;
  late final List<ChapterSummary> _ordered =
      _sortChapters(widget.args.chapters);
  ChapterContent? _chapter;
  bool _loading = true;
  ApiException? _apiError;
  String? _error;
  final ScrollController _scroll = ScrollController();

  /// Incremented per load so a slow response for a previously selected
  /// chapter never replaces the one the user picked last.
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    ScreenSecurity.setSecure(true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    ScreenSecurity.setSecure(false);
    _scroll.dispose();
    super.dispose();
  }

  static List<ChapterSummary> _sortChapters(List<ChapterSummary> chapters) {
    return List<ChapterSummary>.from(chapters)
      ..sort((ChapterSummary a, ChapterSummary b) {
        final int byNumber = a.chapterNumber.compareTo(b.chapterNumber);
        return byNumber != 0 ? byNumber : a.id.compareTo(b.id);
      });
  }

  Future<void> _load() async {
    final int generation = ++_loadGeneration;
    final String chapterId = _chapterId;
    setState(() {
      _loading = true;
      _error = null;
      _apiError = null;
    });
    try {
      final ChapterContent content = await context
          .read<AppContainer>()
          .booksRepository
          .chapterContent(widget.args.bookId, chapterId, force: true);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _chapter = content;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _apiError = error;
        _error = error.userMessage;
        _loading = false;
        _chapter = null;
      });
    } catch (_) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _error = 'Could not open this chapter.';
        _loading = false;
        _chapter = null;
      });
    }
  }

  int get _index =>
      _ordered.indexWhere((ChapterSummary chapter) => chapter.id == _chapterId);

  Future<void> _goTo(int index) async {
    if (index < 0 || index >= _ordered.length) return;
    await _openChapter(_ordered[index].id);
  }

  Future<void> _openChapter(String chapterId) async {
    if (chapterId == _chapterId && _chapter?.id == chapterId) return;
    setState(() => _chapterId = chapterId);
    if (_scroll.hasClients) _scroll.jumpTo(0);
    await _load();
  }

  Future<void> _showChapterList() async {
    final String? selected = await showReaderChapterSheet(
      context,
      chapters: _ordered,
      currentId: _chapterId,
    );
    if (selected != null && mounted) await _openChapter(selected);
  }

  Future<void> _share(BuildContext buttonContext) async {
    final ShareService share = context.read<AppContainer>().shareService;
    if (!share.canShareBooks) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Sharing is not available right now.')),
        );
      return;
    }
    await share.shareBook(
      buttonContext,
      bookId: widget.args.bookId,
      title: widget.args.bookTitle,
    );
  }

  Future<void> _handleRestricted() async {
    final ApiException? error = _apiError;
    if (error == null) return;
    if (error.isAuthenticationRequired || error.isUnauthorized) {
      final bool signedIn = await requireSignIn(
        context,
        message: 'Sign in to read ${widget.args.bookTitle}.',
      );
      if (signedIn && mounted) await _load();
      return;
    }
    if (error.isPurchaseRequired) {
      final CatalogBook book = CatalogBook(
        id: widget.args.bookId,
        title: widget.args.bookTitle,
        description: '',
        author: '',
        language: '',
        accessType: widget.args.accessType,
        price: 0,
        currency: 'INR',
      );
      final bool purchased = await startPaymentFlow(context, book);
      if (purchased && mounted) await _load();
    }
  }

  void _toggleDarkTheme(ReaderPreferences prefs) {
    prefs.setTheme(
      prefs.theme == ReaderThemeMode.dark
          ? ReaderThemeMode.olaichuvadi
          : ReaderThemeMode.dark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ReaderPreferences prefs = context.watch<ReaderPreferences>();
    final ReaderPalette palette = ReaderPalette.of(prefs.theme);
    final int index = _index;
    final bool hasPrevious = index > 0;
    final bool hasNext = index >= 0 && index < _ordered.length - 1;
    final double pageWidth = prefs.width.maxWidth + prefs.width.sidePadding * 2;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.readerChrome,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.readerChrome,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _ReaderHeader(
                title: widget.args.bookTitle,
                onBack: () => AppRouter.pop(context),
                onShare: _share,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm + 2,
                    AppSpacing.xs,
                    AppSpacing.sm + 2,
                    AppSpacing.sm,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: pageWidth),
                      child: Theme(
                        data: palette.theme(),
                        child: ReaderSurface(
                          palette: palette,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: KeyedSubtree(
                              key: ValueKey<String>(
                                _loading ? 'loading' : 'chapter-$_chapterId',
                              ),
                              child: _body(palette, prefs),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _ReaderBottomBar(
                position: index >= 0 && _ordered.isNotEmpty
                    ? 'Chapter ${index + 1}/${_ordered.length}'
                    : null,
                darkTheme: prefs.theme == ReaderThemeMode.dark,
                onChapters: _ordered.isEmpty ? null : _showChapterList,
                onPrevious: hasPrevious ? () => _goTo(index - 1) : null,
                onNext: hasNext ? () => _goTo(index + 1) : null,
                onToggleTheme: () => _toggleDarkTheme(prefs),
                onSettings: () => showReaderSettingsSheet(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(ReaderPalette palette, ReaderPreferences prefs) {
    if (_loading) return const AppLoaderPage();
    if (_apiError != null &&
        (_apiError!.isPurchaseRequired ||
            _apiError!.isAuthenticationRequired)) {
      return AppEmptyState(
        icon: AppIcons.lock,
        title: _apiError!.isPurchaseRequired
            ? 'Purchase required'
            : 'Sign in to continue',
        message: _apiError!.userMessage,
        action: AppButton(
          label: _apiError!.isPurchaseRequired
              ? 'Buy now'
              : 'Continue with Google',
          isExpanded: false,
          backgroundColor: palette.accent,
          foregroundColor: palette.background,
          onPressed: _handleRestricted,
        ),
      );
    }
    if (_error != null) {
      return AppEmptyState(
        icon: AppIcons.error,
        title: 'Could not open chapter',
        message: _error,
        action: AppButton(
          label: 'Retry',
          isExpanded: false,
          backgroundColor: palette.accent,
          foregroundColor: palette.background,
          onPressed: _load,
        ),
      );
    }
    final ChapterContent? chapter = _chapter;
    if (chapter == null) {
      return const AppEmptyState(
        title: 'Chapter unavailable',
        message: 'This chapter could not be opened.',
      );
    }
    final ReadingStyle style = palette.readingStyle(prefs);
    final double side = prefs.width.sidePadding;
    return Scrollbar(
      controller: _scroll,
      child: ListView(
        key: ValueKey<String>('reader-content-${chapter.id}'),
        controller: _scroll,
        padding: EdgeInsets.fromLTRB(
          side,
          AppSpacing.lg,
          side,
          AppSpacing.huge,
        ),
        children: [
          Text(
            'Chapter ${chapter.chapterNumber}',
            style: AppTypography.caption(context).copyWith(
              color: palette.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            header: true,
            child: Text(
              chapter.title,
              style: AppTypography.bookTitle(
                context,
                fontSize: (prefs.fontSize * 1.3).clamp(20.0, 34.0),
                fontWeight: FontWeight.w600,
                color: palette.text,
              ).copyWith(height: 1.45),
            ),
          ),
          SizedBox(height: style.blockSpacing * 1.2),
          RichTextDocumentView(document: chapter.content, style: style),
        ],
      ),
    );
  }
}

class _ReaderHeader extends StatelessWidget {
  const _ReaderHeader({
    required this.title,
    required this.onBack,
    required this.onShare,
  });

  final String title;
  final VoidCallback onBack;
  final ValueChanged<BuildContext> onShare;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.appBarHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.iconButtonTapTarget + AppSpacing.sm,
            ),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.bookTitle(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.readerChromeIcon,
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.xs,
            child: AppIconButton(
              icon: AppIcons.back,
              tooltip: 'Back',
              iconSize: 20,
              color: AppColors.readerChromeIcon,
              onPressed: onBack,
            ),
          ),
          Positioned(
            right: AppSpacing.xs,
            child: Builder(
              builder: (BuildContext buttonContext) => AppIconButton(
                icon: AppIcons.share,
                tooltip: 'Share',
                iconSize: 21,
                color: AppColors.readerChromeIcon,
                onPressed: () => onShare(buttonContext),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderBottomBar extends StatelessWidget {
  const _ReaderBottomBar({
    required this.position,
    required this.darkTheme,
    required this.onChapters,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleTheme,
    required this.onSettings,
  });

  final String? position;
  final bool darkTheme;
  final VoidCallback? onChapters;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onToggleTheme;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).width < 360;
    final double gap = compact ? 2 : AppSpacing.xs;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? AppSpacing.xs : AppSpacing.sm,
          AppSpacing.xs,
          compact ? AppSpacing.xs : AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _ChapterSelector(
                  label: position,
                  onPressed: onChapters,
                ),
              ),
            ),
            _CircleButton(
              icon: AppIcons.chevronLeft,
              tooltip: 'Previous',
              onPressed: onPrevious,
            ),
            SizedBox(width: gap + AppSpacing.xs),
            _CircleButton(
              icon: AppIcons.chevronRight,
              tooltip: 'Next',
              onPressed: onNext,
            ),
            SizedBox(width: gap),
            AppIconButton(
              icon: darkTheme ? AppIcons.lightMode : AppIcons.darkMode,
              tooltip: darkTheme ? 'Olaichuvadi theme' : 'Dark theme',
              iconSize: 22,
              color: AppColors.readerChromeIcon,
              onPressed: onToggleTheme,
            ),
            AppIconButton(
              icon: AppIcons.readerSettings,
              tooltip: 'Reading settings',
              iconSize: 22,
              color: AppColors.readerChromeIcon,
              onPressed: onSettings,
            ),
          ],
        ),
      ),
    );
  }
}

/// List icon plus "Chapter x/N"; opens the chapter list.
class _ChapterSelector extends StatelessWidget {
  const _ChapterSelector({required this.label, required this.onPressed});

  final String? label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Chapters',
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadii.full),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSizes.iconButtonTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    AppIcons.chapters,
                    size: 22,
                    color: AppColors.readerChromeIcon,
                  ),
                  if (label != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    Flexible(
                      child: Text(
                        label!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label(context).copyWith(
                          color: AppColors.readerChromeIcon,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  static const double _size = 40;

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: enabled ? 1 : 0.35,
          child: Material(
            color: AppColors.readerChromeButton,
            shape: CircleBorder(
              side: BorderSide(
                color: AppColors.readerChromeIcon.withOpacity(0.22),
              ),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: SizedBox.square(
                dimension: _size,
                child: Icon(
                  icon,
                  size: 24,
                  color: AppColors.readerChromeIcon,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
