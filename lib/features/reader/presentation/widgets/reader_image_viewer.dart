import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../data/models/rich_text_document.dart';
import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import 'reader_inline_image.dart';

/// Full-screen view of a chapter image with pinch-to-zoom. Closing (the
/// button or system back) pops only this route, so the Reader underneath
/// keeps its chapter and scroll position.
class ReaderImageViewer extends StatelessWidget {
  const ReaderImageViewer({super.key, required this.image});

  final RichTextImage image;

  /// Upper bound for the decoded size of the longest side, in pixels.
  static const int maxDecodeSize = 2560;

  static Future<void> show(BuildContext context, RichTextImage image) {
    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) => ReaderImageViewer(image: image),
        transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final int decode = (math.max(screen.width, screen.height) *
            MediaQuery.devicePixelRatioOf(context))
        .round()
        .clamp(1, maxDecodeSize);
    final String? caption = image.caption;

    return Scaffold(
      backgroundColor: AppColors.readerChrome,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: AppIconButton(
                  key: const ValueKey<String>('reader-image-close'),
                  icon: AppIcons.close,
                  tooltip: 'Close',
                  color: AppColors.brandPrimary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                maxScale: 4,
                child: SizedBox.expand(
                  child: Image(
                    image: ResizeImage(
                      readerImageProvider(image.url),
                      width: decode,
                      height: decode,
                      policy: ResizeImagePolicy.fit,
                    ),
                    fit: BoxFit.contain,
                    semanticLabel: image.alt,
                    excludeFromSemantics: image.alt == null,
                    frameBuilder: (_, Widget child, int? frame, bool sync) {
                      if (sync || frame != null) return child;
                      return const Center(
                        child: SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (BuildContext context, _, __) =>
                        const _ViewerError(),
                  ),
                ),
              ),
            ),
            if (caption != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.md,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: Text(
                  caption,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(context).copyWith(
                    color: AppColors.splashTagline,
                    fontSize: 14,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                    fontFamily: AppTypography.serifFamily,
                    fontFamilyFallback: AppTypography.serifFallbacks,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ViewerError extends StatelessWidget {
  const _ViewerError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            AppIcons.imageUnavailable,
            size: 32,
            color: AppColors.brandPrimary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Image unavailable',
            style: AppTypography.body(context)
                .copyWith(color: AppColors.splashTagline, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
