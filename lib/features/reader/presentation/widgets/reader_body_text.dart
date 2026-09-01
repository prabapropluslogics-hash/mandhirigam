import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/models/reading_prefs.dart';

class ReaderBodyText extends StatelessWidget {
  const ReaderBodyText({
    super.key,
    required this.lead,
    required this.highlight,
    required this.rest,
    required this.prefs,
    required this.textColor,
    required this.highlightColor,
    required this.showDropCap,
    this.onHighlightTap,
  });

  final String lead;
  final String highlight;
  final String rest;
  final ReadingPrefs prefs;
  final Color textColor;
  final Color highlightColor;
  final bool showDropCap;
  final VoidCallback? onHighlightTap;

  @override
  Widget build(BuildContext context) {
    final TextStyle body = AppTypography.readingBody(
      color: textColor,
      fontSize: prefs.fontSize,
      height: prefs.lineHeight,
      fontStyle: prefs.typefaceId == 'fraunces'
          ? FontStyle.italic
          : FontStyle.normal,
    );

    return Text.rich(
      TextSpan(
        style: body,
        children: [
          if (showDropCap)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: AppSpacing.sm,
                  top: AppSpacing.xs,
                ),
                child: Text(
                  'T',
                  style: AppTypography.bookTitle(
                    context,
                    fontSize: AppSizes.dropCapSize,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    height: 0.9,
                  ),
                ),
              ),
            ),
          TextSpan(text: showDropCap ? lead : 'T$lead'),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: onHighlightTap,
              child: Text(
                highlight,
                style: body.copyWith(backgroundColor: highlightColor),
              ),
            ),
          ),
          TextSpan(text: rest),
        ],
      ),
    );
  }
}
