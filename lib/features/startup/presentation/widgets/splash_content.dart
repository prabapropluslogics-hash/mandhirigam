import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_spacing.dart';
import 'splash_brand.dart';
import 'splash_intro.dart';

/// Emblem → title → ornament → tagline → [status], each revealed in turn.
///
/// [status] is supplied by the screen (loader or error/retry) so this widget
/// stays free of startup logic.
class SplashContent extends StatelessWidget {
  const SplashContent({
    super.key,
    required this.progress,
    required this.status,
  });

  final Animation<double> progress;
  final Widget status;

  /// Below this height (landscape phones) spacing and sizes tighten.
  static const double _compactHeight = 560;

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    final bool compact = screen.height < _compactHeight;
    final double scale = (screen.shortestSide / 390).clamp(0.85, 1.2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SplashReveal(
          progress: progress,
          begin: 0.25,
          end: 0.6,
          scaleFrom: 0.96,
          child: SplashEmblem(size: (compact ? 48 : 64) * scale),
        ),
        SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
        SplashReveal(
          progress: progress,
          begin: 0.35,
          end: 0.8,
          scaleFrom: 0.97,
          child: SplashTitle(fontSize: 30 * scale),
        ),
        const SizedBox(height: AppSpacing.md),
        SplashReveal(
          progress: progress,
          begin: 0.5,
          end: 0.85,
          child: SplashOrnament(lineWidth: 40 * scale),
        ),
        const SizedBox(height: AppSpacing.md),
        SplashReveal(
          progress: progress,
          begin: 0.55,
          end: 0.9,
          child: const SplashTagline(),
        ),
        SizedBox(height: compact ? AppSpacing.xxl : AppSpacing.massive),
        SplashReveal(
          progress: progress,
          begin: 0.7,
          end: 1,
          child: status,
        ),
      ],
    );
  }
}
