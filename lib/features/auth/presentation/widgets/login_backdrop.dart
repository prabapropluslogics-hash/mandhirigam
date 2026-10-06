import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';

/// Obsidian login background in the splash's language: charcoal gradient,
/// a soft warm glow behind the illustration, two faint botanical sprigs
/// flanking it, sparse dust and a vignette.
class LoginBackdrop extends StatelessWidget {
  const LoginBackdrop({super.key});

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
                  AppColors.splashDeep,
                ],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.1),
                radius: 0.8,
                colors: [
                  AppColors.brandAccent.withOpacity(0.08),
                  AppColors.splashGlow.withOpacity(0.035),
                  AppColors.splashGlow.withOpacity(0),
                ],
                stops: const [0, 0.45, 1],
              ),
            ),
          ),
          const RepaintBoundary(
            child: CustomPaint(painter: _BotanicalPainter()),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.1),
                radius: 1.25,
                colors: [
                  AppColors.splashDeep.withOpacity(0),
                  AppColors.splashDeep.withOpacity(0.6),
                ],
                stops: const [0.55, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotanicalPainter extends CustomPainter {
  const _BotanicalPainter();

  static const int _seed = 1729;
  static const int _dustCount = 28;

  @override
  void paint(Canvas canvas, Size size) {
    final double unit = size.shortestSide;
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round
      ..color = AppColors.brandPrimary.withOpacity(0.08);

    _sprig(
      canvas,
      line,
      start: Offset(size.width + 4, size.height * 0.44),
      control: Offset(size.width * 0.86, size.height * 0.36),
      end: Offset(size.width * 0.80, size.height * 0.24),
      leaf: unit * 0.07,
    );
    _sprig(
      canvas,
      line,
      start: Offset(-4, size.height * 0.50),
      control: Offset(size.width * 0.12, size.height * 0.56),
      end: Offset(size.width * 0.17, size.height * 0.68),
      leaf: unit * 0.06,
    );

    final math.Random random = math.Random(_seed);
    final Paint dust = Paint();
    for (int i = 0; i < _dustCount; i++) {
      final Offset point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height * 0.75,
      );
      dust.color =
          AppColors.brandAccent.withOpacity(0.05 + random.nextDouble() * 0.12);
      canvas.drawCircle(point, 0.4 + random.nextDouble() * 0.8, dust);
    }
  }

  /// A curved stem with leaves alternating along it.
  void _sprig(
    Canvas canvas,
    Paint paint, {
    required Offset start,
    required Offset control,
    required Offset end,
    required double leaf,
  }) {
    canvas.drawPath(
      Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy),
      paint,
    );

    const int leaves = 5;
    for (int i = 1; i <= leaves; i++) {
      final double t = i / (leaves + 0.5);
      final Offset point = _bezier(start, control, end, t);
      final Offset tangent = _bezierTangent(start, control, end, t);
      final double side = i.isEven ? 1 : -1;
      final double angle = math.atan2(tangent.dy, tangent.dx) + side * 0.75;
      _leaf(canvas, paint, point, angle, leaf * (1 - t * 0.35));
    }
  }

  void _leaf(
      Canvas canvas, Paint paint, Offset base, double angle, double length) {
    final double width = length * 0.34;
    canvas
      ..save()
      ..translate(base.dx, base.dy)
      ..rotate(angle)
      ..drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(length * 0.45, -width, length, 0)
          ..quadraticBezierTo(length * 0.45, width, 0, 0),
        paint,
      )
      ..drawLine(Offset.zero, Offset(length * 0.75, 0), paint)
      ..restore();
  }

  Offset _bezier(Offset a, Offset b, Offset c, double t) {
    final double u = 1 - t;
    return a * (u * u) + b * (2 * u * t) + c * (t * t);
  }

  Offset _bezierTangent(Offset a, Offset b, Offset c, double t) {
    return (b - a) * (2 * (1 - t)) + (c - b) * (2 * t);
  }

  @override
  bool shouldRepaint(covariant _BotanicalPainter oldDelegate) => false;
}
