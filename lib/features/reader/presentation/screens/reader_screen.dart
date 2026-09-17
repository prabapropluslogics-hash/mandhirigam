import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/app_container.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/security/screen_security.dart';
import '../../../../data/models/catalog_book.dart';
import '../../../../data/models/chapter.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/feedback/app_empty_state.dart';
import '../../../../design_system/components/feedback/app_loader.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../routing/app_router.dart';
import '../../../../routing/app_routes.dart';
import '../../../../state/library_controller.dart';
import '../../../book_details/presentation/screens/book_details_screen.dart';
import '../../../payment/presentation/payment_flow.dart';
import '../widgets/rich_text_document_view.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.args});

  final ReaderArgs args;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late String _chapterId = widget.args.chapterId;
  ChapterContent? _chapter;
  bool _loading = true;
  ApiException? _apiError;
  String? _error;

  @override
  void initState() {
    super.initState();
    ScreenSecurity.setSecure(true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    ScreenSecurity.setSecure(false);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _apiError = null;
    });
    try {
      final ChapterContent content = await context
          .read<AppContainer>()
          .booksRepository
          .chapterContent(widget.args.bookId, _chapterId, force: true);
      if (!mounted) return;
      setState(() {
        _chapter = content;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _apiError = error;
        _error = error.userMessage;
        _loading = false;
        _chapter = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not open this chapter.';
        _loading = false;
      });
    }
  }

  List<ChapterSummary> get _ordered {
    final List<ChapterSummary> chapters =
        List<ChapterSummary>.from(widget.args.chapters);
    chapters.sort((ChapterSummary a, ChapterSummary b) {
      final int byNumber = a.chapterNumber.compareTo(b.chapterNumber);
      return byNumber != 0 ? byNumber : a.id.compareTo(b.id);
    });
    return chapters;
  }

  int get _index =>
      _ordered.indexWhere((ChapterSummary chapter) => chapter.id == _chapterId);

  Future<void> _goTo(int index) async {
    if (index < 0 || index >= _ordered.length) return;
    _chapterId = _ordered[index].id;
    await _load();
  }

  Future<void> _handleRestricted() async {
    final ApiException? error = _apiError;
    if (error == null) return;
    if (error.isAuthenticationRequired || error.isUnauthorized) {
      await AppRouter.pushNamed<bool>(
        context,
        AppRoutes.login,
        arguments: error.userMessage,
      );
      if (mounted) await _load();
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
      if (purchased && mounted) {
        await context.read<LibraryController>().refresh();
        await _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int index = _index;
    final bool hasPrevious = index > 0;
    final bool hasNext = index >= 0 && index < _ordered.length - 1;

    return AppScaffold(
      safeAreaBottom: false,
      body: Column(
        children: [
          Padding(
            padding: AppInsets.pageHorizontal,
            child: Row(
              children: [
                AppIconButton(
                  icon: AppIcons.back,
                  tooltip: 'Back',
                  onPressed: () => AppRouter.pop(context),
                ),
                Expanded(
                  child: Text(
                    widget.args.bookTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.sectionTitle(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _body()),
          SafeArea(
            top: false,
            child: Padding(
              padding: AppInsets.page,
              child: Row(
                children: [
                  Expanded(
                    child: AppOutlinedButton(
                      label: 'Previous',
                      onPressed: hasPrevious ? () => _goTo(index - 1) : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: 'Next',
                      onPressed: hasNext ? () => _goTo(index + 1) : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
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
          label: _apiError!.isPurchaseRequired ? 'Buy now' : 'Continue with Google',
          isExpanded: false,
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xxxl,
      ),
      children: [
        Text(
          'Chapter ${chapter.chapterNumber}',
          style: AppTypography.helper(context),
        ),
        const AppGap.xs(),
        Text(chapter.title, style: AppTypography.pageTitle(context)),
        const AppGap.xl(),
        RichTextDocumentView(document: chapter.content),
      ],
    );
  }
}
