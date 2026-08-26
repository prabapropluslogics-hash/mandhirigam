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
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppInsets.pageHorizontal,
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: AppTypography.sectionTitle(context)),
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
