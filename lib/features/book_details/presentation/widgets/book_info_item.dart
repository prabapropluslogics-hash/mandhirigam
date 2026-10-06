import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';

class BookInfoItem extends StatelessWidget {
  const BookInfoItem({
    super.key,
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: AppTypography.sectionTitle(context).copyWith(
                color: AppColors.textPrimaryDark,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              style: AppTypography.caption(context).copyWith(
                fontSize: 10.5,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Three equal metadata columns on a quiet charcoal panel, split by
/// hairline gold dividers.
class BookInfoRow extends StatelessWidget {
  const BookInfoRow({
    super.key,
    required this.chapters,
    required this.access,
    required this.language,
  });

  final String chapters;
  final String access;
  final String language;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: AppColors.brandPrimary.withOpacity(0.14),
          width: 0.8,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: BookInfoItem(value: chapters, label: 'Chapters')),
            const _Separator(),
            Expanded(child: BookInfoItem(value: access, label: 'Access')),
            const _Separator(),
            Expanded(child: BookInfoItem(value: language, label: 'Language')),
          ],
        ),
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: SizedBox(
        width: 0.8,
        child: ColoredBox(color: AppColors.brandPrimary.withOpacity(0.18)),
      ),
    );
  }
}
