import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design_system/theme/app_colors.dart';

/// Barely-there atmosphere behind the main tabs: a warm charcoal tint at the
/// top, a soft gold glow near the top content, a fainter warm lift lower
/// down, faint manuscript ruling with sparse dust, and a deepening toward the
/// bottom. Paints over the scaffold colour and never intercepts input.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.splashCharcoal,
                  AppColors.backgroundDark,
                  AppColors.backgroundDark,
                  AppColors.splashBase,
                ],
                stops: [0, 0.42, 0.75, 1],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.65),
                radius: 0.9,
                colors: [
                  AppColors.splashGlow.withOpacity(0.07),
                  AppColors.splashGlow.withOpacity(0.02),
                  AppColors.splashGlow.withOpacity(0),
                ],
                stops: const [0, 0.5, 1],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.95, 0.3),
                radius: 0.9,
                colors: [
                  AppColors.splashGlow.withOpacity(0.03),
                  AppColors.splashGlow.withOpacity(0),
                ],
              ),
            ),
          ),
          const RepaintBoundary(
            child: CustomPaint(painter: _ManuscriptTexturePainter()),
          ),
        ],
      ),
    );
  }
}

class _ManuscriptTexturePainter extends CustomPainter {
  const _ManuscriptTexturePainter();

  static const double _spacing = 28;
  static const double _coverage = 0.55;
  static const double _maxOpacity = 0.02;
  static const int _seed = 1729;
  static const int _dustCount = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final double limit = size.height * _coverage;
    final Paint rule = Paint()..strokeWidth = 0.5;
    for (double y = _spacing; y < limit; y += _spacing) {
      final double opacity = _maxOpacity * (1 - y / limit);
      rule.shader = LinearGradient(
        colors: [
          AppColors.neutral100.withOpacity(0),
          AppColors.neutral100.withOpacity(opacity),
          AppColors.neutral100.withOpacity(0),
        ],
      ).createShader(Rect.fromLTWH(0, y, size.width, 1));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rule);
    }

    final math.Random random = math.Random(_seed);
    final Paint dust = Paint();
    for (int i = 0; i < _dustCount; i++) {
      final double y = random.nextDouble() * limit;
      final double fade = 1 - y / limit;
      dust.color = AppColors.brandAccent
          .withOpacity((0.04 + random.nextDouble() * 0.1) * fade);
      canvas.drawCircle(
        Offset(random.nextDouble() * size.width, y),
        0.4 + random.nextDouble() * 0.7,
        dust,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ManuscriptTexturePainter oldDelegate) => false;
}
