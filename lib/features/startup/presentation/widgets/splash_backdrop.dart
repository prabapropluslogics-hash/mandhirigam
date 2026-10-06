import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';
import 'splash_intro.dart';

/// Vertical anchor (as an [Alignment.y]) shared by the glow and the celestial
/// motif so both sit just behind the wordmark.
const double _focusY = -0.12;

/// Obsidian splash background: charcoal gradient, warm gold glow, faint
/// celestial geometry, manuscript ruling and dust.
///
/// Starts as the flat [AppColors.splashBase] (identical to the native launch
/// colour) and reveals each layer in sequence with [progress].
class SplashBackdrop extends StatelessWidget {
  const SplashBackdrop({super.key, required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.splashBase,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SplashReveal(
            progress: progress,
            begin: 0,
            end: 0.35,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.splashCharcoal,
                    AppColors.splashBase,
                    AppColors.splashDeep,
                  ],
                  stops: [0, 0.55, 1],
                ),
              ),
            ),
          ),
          SplashReveal(
            progress: progress,
            begin: 0.1,
            end: 0.55,
            child: const _GoldGlow(),
          ),
          SplashReveal(
            progress: progress,
            begin: 0.2,
            end: 0.75,
            child: const RepaintBoundary(
              child: CustomPaint(painter: _ManuscriptPainter()),
            ),
          ),
          SplashReveal(
            progress: progress,
            begin: 0.25,
            end: 0.8,
            child: const RepaintBoundary(
              child: CustomPaint(painter: _CelestialPainter()),
            ),
          ),
          SplashReveal(
            progress: progress,
            begin: 0,
            end: 0.35,
            child: const _Vignette(),
          ),
        ],
      ),
    );
  }
}

class _GoldGlow extends StatelessWidget {
  const _GoldGlow();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, _focusY),
          radius: 0.8,
          colors: [
            AppColors.brandAccent.withOpacity(0.13),
            AppColors.splashGlow.withOpacity(0.08),
            AppColors.splashGlow.withOpacity(0.03),
            AppColors.splashGlow.withOpacity(0),
          ],
          stops: const [0, 0.25, 0.6, 1],
        ),
      ),
    );
  }
}

class _Vignette extends StatelessWidget {
  const _Vignette();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, _focusY),
          radius: 1.2,
          colors: [
            AppColors.splashDeep.withOpacity(0),
            AppColors.splashDeep.withOpacity(0.7),
          ],
          stops: const [0.5, 1],
        ),
      ),
    );
  }
}

/// Faint ruled lines (manuscript texture) and deterministic dust motes.
class _ManuscriptPainter extends CustomPainter {
  const _ManuscriptPainter();

  static const int _seed = 1729;
  static const int _dustCount = 48;
  static const int _moteCount = 7;
  static const double _ruleSpacing = 26;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;

    final Paint rule = Paint()
      ..strokeWidth = 0.5
      ..shader = LinearGradient(
        colors: [
          AppColors.neutral100.withOpacity(0),
          AppColors.neutral100.withOpacity(0.022),
          AppColors.neutral100.withOpacity(0),
        ],
      ).createShader(bounds);
    for (double y = _ruleSpacing; y < size.height; y += _ruleSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), rule);
    }

    final math.Random random = math.Random(_seed);
    final Paint dust = Paint();
    for (int i = 0; i < _dustCount; i++) {
      final Offset point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      dust.color =
          AppColors.brandAccent.withOpacity(0.04 + random.nextDouble() * 0.12);
      canvas.drawCircle(point, 0.4 + random.nextDouble() * 0.8, dust);
    }

    final Paint mote = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    for (int i = 0; i < _moteCount; i++) {
      final Offset point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      mote.color =
          AppColors.brandAccent.withOpacity(0.05 + random.nextDouble() * 0.07);
      canvas.drawCircle(point, 1.6 + random.nextDouble(), mote);
    }
  }

  @override
  bool shouldRepaint(covariant _ManuscriptPainter oldDelegate) => false;
}

/// Fine-line celestial dial: concentric orbits, a tick ring, orbit fragments
/// and a few nodes.
class _CelestialPainter extends CustomPainter {
  const _CelestialPainter();

  static const int _tickCount = 72;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center =
        Offset(size.width / 2, size.height * (1 + _focusY) / 2);
    final double unit = size.shortestSide;
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    const List<(double, double)> orbits = [
      (0.30, 0.07),
      (0.38, 0.05),
      (0.58, 0.035),
    ];
    for (final (double radius, double opacity) in orbits) {
      stroke.color = AppColors.brandPrimary.withOpacity(opacity);
      canvas.drawCircle(center, unit * radius, stroke);
    }

    final double tickRadius = unit * 0.38;
    for (int i = 0; i < _tickCount; i++) {
      final double angle = i * 2 * math.pi / _tickCount;
      final bool major = i % 6 == 0;
      final Offset direction = Offset(math.cos(angle), math.sin(angle));
      final double length = unit * (major ? 0.022 : 0.009);
      stroke.color = AppColors.brandPrimary.withOpacity(major ? 0.09 : 0.05);
      canvas.drawLine(
        center + direction * tickRadius,
        center + direction * (tickRadius + length),
        stroke,
      );
    }

    final Rect fragmentRect =
        Rect.fromCircle(center: center, radius: unit * 0.47);
    stroke.color = AppColors.brandPrimary.withOpacity(0.06);
    canvas.drawArc(fragmentRect, -math.pi * 0.85, math.pi * 0.45, false, stroke);
    canvas.drawArc(fragmentRect, math.pi * 0.15, math.pi * 0.45, false, stroke);

    final Paint node = Paint()
      ..color = AppColors.brandAccent.withOpacity(0.18);
    final double nodeRadius = unit * 0.30;
    for (final double angle in const [-0.95, 2.65, 5.55]) {
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * nodeRadius,
        1.6,
        node,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CelestialPainter oldDelegate) => false;
}
