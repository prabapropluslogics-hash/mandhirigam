import 'package:flutter/material.dart';

import '../../../../data/models/chapter.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';

/// Lists the book's chapters; returns the picked chapter id.
Future<String?> showReaderChapterSheet(
  BuildContext context, {
  required List<ChapterSummary> chapters,
  required String currentId,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surfaceDark,
    barrierColor: AppColors.overlay.withOpacity(0.45),
    shape: RoundedRectangleBorder(borderRadius: AppRadii.bottomSheetBorder),
    builder: (BuildContext sheetContext) => _ChapterSheet(
      chapters: chapters,
      currentId: currentId,
    ),
  );
}

class _ChapterSheet extends StatefulWidget {
  const _ChapterSheet({required this.chapters, required this.currentId});

  final List<ChapterSummary> chapters;
  final String currentId;

  @override
  State<_ChapterSheet> createState() => _ChapterSheetState();
}

class _ChapterSheetState extends State<_ChapterSheet> {
  final GlobalKey _currentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? current = _currentKey.currentContext;
      if (current != null) {
        Scrollable.ensureVisible(current, alignment: 0.3);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final int count = widget.chapters.length;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppGap.md(),
            Center(
              child: Container(
                width: AppSizes.bottomSheetHandleWidth,
                height: AppSizes.bottomSheetHandleHeight,
                decoration: BoxDecoration(
                  color: AppColors.neutral600,
                  borderRadius: BorderRadius.circular(AppRadii.full),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      'Chapters',
                      style: AppTypography.bookTitle(
                        context,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                  ),
                  Text(
                    count == 1 ? '1 chapter' : '$count chapters',
                    style: AppTypography.caption(context).copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: AppColors.brandPrimary.withOpacity(0.18),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: count,
                itemBuilder: (BuildContext context, int index) {
                  final ChapterSummary chapter = widget.chapters[index];
                  final bool current = chapter.id == widget.currentId;
                  return _ChapterTile(
                    key: ValueKey<String>('reader-chapter-${chapter.id}'),
                    anchorKey: current ? _currentKey : null,
                    chapter: chapter,
                    current: current,
                    onTap: () => Navigator.of(context).pop(chapter.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({
    super.key,
    required this.anchorKey,
    required this.chapter,
    required this.current,
    required this.onTap,
  });

  final Key? anchorKey;
  final ChapterSummary chapter;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        current ? AppColors.brandAccent : AppColors.neutral200;
    final Color numberColor =
        current ? AppColors.brandPrimary : AppColors.neutral400;
    return Semantics(
      selected: current,
      button: true,
      child: Material(
        key: anchorKey,
        color: current
            ? AppColors.brandPrimary.withOpacity(0.08)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 60),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: current ? AppColors.brandPrimary : Colors.transparent,
                  width: 2.5,
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    chapter.chapterNumber.toString().padLeft(2, '0'),
                    style: AppTypography.bookTitle(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: numberColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    chapter.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.body(context).copyWith(
                      color: titleColor,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: current ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (current) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Reading',
                    style: AppTypography.caption(context).copyWith(
                      color: AppColors.brandPrimary,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
