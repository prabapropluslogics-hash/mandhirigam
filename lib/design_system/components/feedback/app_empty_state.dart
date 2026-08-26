import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../layout/app_gap.dart';

/// Reusable empty / error placeholder for lists and content regions.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = AppIcons.empty,
    this.action,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: AppInsets.xxl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSizes.iconHuge, color: colors.outline),
            const AppGap.lg(),
            Text(
              title,
              style: AppTypography.sectionTitle(context),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const AppGap.sm(),
              Text(
                message!,
                style: AppTypography.helper(context),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const AppGap.xl(),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
