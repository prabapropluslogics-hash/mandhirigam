import 'package:flutter/material.dart';

import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/models/book.dart';
import '../../../../shared/models/profile_stats.dart';

class ReaderProgressFooter extends StatelessWidget {
  const ReaderProgressFooter({
    super.key,
    required this.book,
    required this.chapterIndex,
    required this.progress,
    required this.textColor,
    required this.trackColor,
    required this.onPrevious,
    required this.onNext,
    this.onChapterTap,
  });

  final Book book;
  final int chapterIndex;
  final ReaderProgress progress;
  final Color textColor;
  final Color trackColor;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onChapterTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.full),
          child: LinearProgressIndicator(
            value: progress.percent,
            minHeight: AppSizes.progressHeight,
            backgroundColor: trackColor,
            color: AppColors.brandPrimary,
          ),
        ),
        const AppGap.sm(),
        Row(
          children: [
            Expanded(
              child: Text(
                progress.pageLabel,
                style: AppTypography.caption(context).copyWith(color: textColor),
              ),
            ),
            Text(
              progress.remainingLabel,
              style: AppTypography.caption(context).copyWith(color: textColor),
            ),
          ],
        ),
        const AppGap.md(),
        DecoratedBox(
          decoration: BoxDecoration(
            color: trackColor,
            borderRadius: AppRadii.chipBorder,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                AppIconButton(
                  icon: AppIcons.chevronLeft,
                  tooltip: 'Previous chapter',
                  backgroundColor: AppColors.neutral100,
                  color: AppColors.textPrimary,
                  onPressed: onPrevious,
                  disabled: onPrevious == null,
                ),
                Expanded(
                  child: InkWell(
                    onTap: onChapterTap,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          AppIcons.chapter,
                          size: AppSizes.iconSm,
                          color: textColor,
                        ),
                        const AppGap.sm(axis: AppGapAxis.horizontal),
                        Flexible(
                          child: Text(
                            'Chapter ${chapterIndex + 1} of ${book.totalChapters}',
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.label(context).copyWith(
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AppIconButton(
                  icon: AppIcons.chevronRight,
                  tooltip: 'Next chapter',
                  backgroundColor: AppColors.neutral900,
                  color: AppColors.neutral0,
                  onPressed: onNext,
                  disabled: onNext == null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
