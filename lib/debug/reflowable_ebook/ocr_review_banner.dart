import 'package:flutter/material.dart';

import '../../design_system/theme/app_spacing.dart';
import '../../design_system/theme/app_typography.dart';
import 'fixture_loader.dart';

/// Explicit warning that fixture / OCR Tamil is unreviewed.
///
/// Do not hide this banner or silently rewrite OCR strings for demos.
class OcrReviewBanner extends StatelessWidget {
  const OcrReviewBanner({
    super.key,
    required this.reviewNotes,
  });

  final ChapterReviewNotes reviewNotes;

  @override
  Widget build(BuildContext context) {
    if (!reviewNotes.humanVerificationRequired && reviewNotes.notes.isEmpty) {
      return const SizedBox.shrink();
    }
    return Material(
      color: const Color(0xFF5C3A12).withOpacity(0.92),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'OCR / source verification required',
              style: AppTypography.caption(context).copyWith(
                color: const Color(0xFFFFE7C2),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Fixture Tamil text is unreviewed. Verify against the source PDF '
              'before any client demonstration. Do not treat this as published '
              'content. ALLOW_RICH_TEXT_V2_PUBLISH remains disabled.',
              style: AppTypography.caption(context).copyWith(
                color: const Color(0xFFE6DAC2),
                height: 1.35,
              ),
            ),
            if (reviewNotes.notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              for (final String note in reviewNotes.notes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $note',
                    style: AppTypography.caption(context).copyWith(
                      color: const Color(0xFFD2C2A4),
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
