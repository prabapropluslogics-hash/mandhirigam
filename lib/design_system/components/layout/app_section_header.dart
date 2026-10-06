import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../buttons/app_text_button.dart';

/// Editorial section title: a small gold eyebrow ([title]), an optional serif
/// [subtitle] and an optional trailing action (e.g. See all).
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    const Color gold = AppColors.brandPrimary;
    final String? subtitle = this.subtitle;
    return Padding(
      padding: AppInsets.pageHorizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: AppSpacing.md,
                        height: 1,
                        child: ColoredBox(color: gold.withOpacity(0.7)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.label(context).copyWith(
                            color: gold,
                            fontSize: 12,
                            letterSpacing: 1.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bookTitle(
                        context,
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimaryDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (actionLabel != null)
            AppTextButton(
              label: actionLabel!,
              onPressed: onAction,
              compact: true,
              trailingIcon: AppIcons.chevronRight,
              foregroundColor: gold,
            ),
        ],
      ),
    );
  }
}
