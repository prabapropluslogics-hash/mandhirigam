import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';

/// The four-colour Google "G", drawn locally so no logo asset is needed.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: const CustomPaint(painter: _GoogleMarkPainter()),
      ),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double stroke = size.shortestSide * 0.2;
    final double radius = size.shortestSide / 2 - stroke / 2;
    final Offset center = size.center(Offset.zero);
    final Rect ring = Rect.fromCircle(center: center, radius: radius);
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    const List<(Color, double, double)> arcs = [
      (AppColors.googleBlue, 0, 0.25),
      (AppColors.googleGreen, 0.25, 0.6),
      (AppColors.googleYellow, 0.85, 0.3),
      (AppColors.googleRed, 1.15, 0.6),
    ];
    for (final (Color color, double start, double sweep) in arcs) {
      paint.color = color;
      canvas.drawArc(ring, start * math.pi, sweep * math.pi, false, paint);
    }

    canvas.drawRect(
      Rect.fromLTRB(
        center.dx,
        center.dy - stroke / 2,
        center.dx + radius + stroke / 2,
        center.dy + stroke / 2,
      ),
      Paint()..color = AppColors.googleBlue,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleMarkPainter oldDelegate) => false;
}
