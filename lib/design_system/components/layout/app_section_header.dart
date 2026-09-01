import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../buttons/app_text_button.dart';

/// Section title with an optional trailing action (e.g. See all).
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.serif = false,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool serif;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppInsets.pageHorizontal,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: serif
                  ? AppTypography.bookTitle(context, fontSize: 18)
                  : AppTypography.sectionTitle(context),
            ),
          ),
          if (actionLabel != null)
            AppTextButton(
              label: actionLabel!,
              onPressed: onAction,
              compact: true,
            ),
        ],
      ),
    );
  }
}
