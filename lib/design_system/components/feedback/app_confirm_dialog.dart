import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../buttons/app_text_button.dart';

/// Returns `true` if the user confirms, `false` if they cancel or dismiss.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      final ColorScheme colors = Theme.of(dialogContext).colorScheme;

      return AlertDialog(
        title: Text(title, style: AppTypography.sectionTitle(dialogContext)),
        content: Text(message, style: AppTypography.bodySmall(dialogContext)),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.none,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        actions: [
          AppTextButton(
            label: cancelLabel,
            compact: true,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor:
                  isDestructive ? AppColors.dangerSoft : colors.primary,
            ),
            child: Text(confirmLabel),
          ),
        ],
      );
    },
  );

  return result ?? false;
}
