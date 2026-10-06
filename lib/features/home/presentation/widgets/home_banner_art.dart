import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';

/// Horizontal anchor of every artwork, leaving the left side for text.
const double _artCenterX = 0.72;

Offset _artCenter(Size size) =>
    Offset(size.width * _artCenterX, size.height / 2);

/// An open book with a soft cone of light and a few rising motes.
class OpenBookLightArt extends CustomPainter {
  const OpenBookLightArt();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = _artCenter(size);
    final double u = size.height;
    final double spineBottom = c.dy + 0.32 * u;
    final double pageTop = c.dy + 0.08 * u;
    final double halfWidth = 0.42 * u;

    final Path beam = Path()
      ..moveTo(c.dx - 0.04 * u, pageTop)
      ..lineTo(c.dx - 0.36 * u, c.dy - 0.5 * u)
      ..lineTo(c.dx + 0.36 * u, c.dy - 0.5 * u)
      ..lineTo(c.dx + 0.04 * u, pageTop)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.brandAccent.withOpacity(0.2),
            AppColors.brandAccent.withOpacity(0),
          ],
        ).createShader(beam.getBounds()),
    );

    final Paint ray = Paint()..strokeWidth = 0.6;
    for (int i = 0; i < 7; i++) {
      final double angle = -math.pi / 2 + (i - 3) * 0.12;
      final Offset start = Offset(c.dx, pageTop);
      final Offset end =
          start + Offset(math.cos(angle), math.sin(angle)) * (0.62 * u);
      ray.shader = LinearGradient(
        colors: [
          AppColors.brandAccent.withOpacity(0.35),
          AppColors.brandAccent.withOpacity(0),
        ],
      ).createShader(Rect.fromPoints(start, end));
      canvas.drawLine(start, end, ray);
    }

    Path page(double side) => Path()
      ..moveTo(c.dx, spineBottom)
      ..quadraticBezierTo(c.dx + side * 0.2 * u, spineBottom - 0.07 * u,
          c.dx + side * halfWidth, spineBottom - 0.03 * u)
      ..lineTo(c.dx + side * halfWidth, pageTop + 0.02 * u)
      ..quadraticBezierTo(
          c.dx + side * 0.2 * u, pageTop - 0.05 * u, c.dx, pageTop + 0.04 * u)
      ..close();

    final Rect bookRect = Rect.fromLTRB(
        c.dx - halfWidth, pageTop - 0.05 * u, c.dx + halfWidth, spineBottom);
    final Paint pageFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.neutral50.withOpacity(0.2),
          AppColors.neutral50.withOpacity(0.05),
        ],
      ).createShader(bookRect);
    final Paint pageEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AppColors.brandAccent.withOpacity(0.5);
    final Paint pageLine = Paint()
      ..strokeWidth = 0.6
      ..color = AppColors.brandAccent.withOpacity(0.16);

    for (final double side in const [-1.0, 1.0]) {
      final Path p = page(side);
      canvas.drawPath(p, pageFill);
      canvas.drawPath(p, pageEdge);
      for (int i = 1; i <= 4; i++) {
        final double y = pageTop + 0.03 * u + i * 0.045 * u;
        canvas.drawLine(
          Offset(c.dx + side * 0.07 * u, y),
          Offset(c.dx + side * (halfWidth - 0.06 * u), y - 0.01 * u),
          pageLine,
        );
      }
    }
    canvas.drawLine(
        Offset(c.dx, pageTop + 0.04 * u), Offset(c.dx, spineBottom), pageEdge);

    final math.Random random = math.Random(11);
    final Paint mote = Paint();
    for (int i = 0; i < 14; i++) {
      final double t = random.nextDouble();
      final double spread = (random.nextDouble() - 0.5) * 0.6 * u * (1 - t);
      mote.color =
          AppColors.brandAccent.withOpacity(0.2 + random.nextDouble() * 0.35);
      canvas.drawCircle(
        Offset(c.dx + spread, pageTop - t * 0.5 * u),
        0.6 + random.nextDouble() * 0.9,
        mote,
      );
    }
  }

  @override
  bool shouldRepaint(covariant OpenBookLightArt oldDelegate) => false;
}

/// Three stacked palm-leaf manuscript folios bound by a thread.
class PalmLeafArt extends CustomPainter {
  const PalmLeafArt();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = _artCenter(size);
    final double u = size.height;
    final double leafWidth = math.min(size.width * 0.5, 1.5 * u);
    final double leafHeight = 0.16 * u;
    final double holeOffset = leafWidth * 0.28;

    const List<(double, double, double)> leaves = [
      (-0.22, 0.0, -0.05),
      (0.0, 0.04, 0.03),
      (0.22, -0.03, -0.02),
    ];

    final Paint edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = AppColors.brandAccent.withOpacity(0.38);
    final Paint ink = Paint()
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round
      ..color = AppColors.splashBase.withOpacity(0.55);
    final Paint hole = Paint()..color = AppColors.splashBase.withOpacity(0.85);

    for (int i = 0; i < leaves.length; i++) {
      final (double dy, double dx, double angle) = leaves[i];
      canvas.save();
      canvas.translate(c.dx + dx * u, c.dy + dy * u);
      canvas.rotate(angle);
      final Rect rect = Rect.fromCenter(
          center: Offset.zero, width: leafWidth, height: leafHeight);
      final RRect leaf =
          RRect.fromRectAndRadius(rect, Radius.circular(leafHeight / 2));
      canvas.drawRRect(
        leaf,
        Paint()
          ..shader = LinearGradient(
            colors: [
              AppColors.featuredStart.withOpacity(0.2),
              AppColors.featuredMid.withOpacity(0.32),
              AppColors.featuredStart.withOpacity(0.16),
            ],
          ).createShader(rect),
      );
      canvas.drawRRect(leaf, edge);

      final math.Random random = math.Random(31 + i);
      for (final double row in const [-0.025, 0.025]) {
        double x = rect.left + 0.1 * u;
        while (x < rect.right - 0.1 * u) {
          final double length = (0.02 + random.nextDouble() * 0.05) * u;
          final double end = math.min(x + length, rect.right - 0.1 * u);
          final bool overlapsHole = <double>[-holeOffset, holeOffset].any(
            (double h) => end > h - 0.03 * u && x < h + 0.03 * u,
          );
          if (!overlapsHole) {
            canvas.drawLine(Offset(x, row * u), Offset(end, row * u), ink);
          }
          x = end + 0.014 * u;
        }
      }
      canvas.drawCircle(Offset(-holeOffset, 0), 0.013 * u, hole);
      canvas.drawCircle(Offset(holeOffset, 0), 0.013 * u, hole);
      canvas.restore();
    }

    final Paint thread = Paint()
      ..strokeWidth = 0.8
      ..color = AppColors.brandPrimary.withOpacity(0.4);
    canvas.drawLine(
      Offset(c.dx - holeOffset, c.dy - 0.34 * u),
      Offset(c.dx - holeOffset, c.dy + 0.34 * u),
      thread,
    );
  }

  @override
  bool shouldRepaint(covariant PalmLeafArt oldDelegate) => false;
}

/// An arched reading-room window casting light over a shelf of spines.
class LibraryArchArt extends CustomPainter {
  const LibraryArchArt();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = _artCenter(size);
    final double u = size.height;
    final double archHalf = 0.24 * u;
    final double archTop = c.dy - 0.42 * u;
    final double shelfY = c.dy + 0.34 * u;
    final double archBottom = shelfY - 0.12 * u;

    final Path arch = Path()
      ..moveTo(c.dx - archHalf, archBottom)
      ..lineTo(c.dx - archHalf, archTop + archHalf)
      ..arcToPoint(Offset(c.dx + archHalf, archTop + archHalf),
          radius: Radius.circular(archHalf))
      ..lineTo(c.dx + archHalf, archBottom)
      ..close();
    final Rect archRect = arch.getBounds();
    canvas.drawPath(
      arch,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 0.8,
          colors: [
            AppColors.brandAccent.withOpacity(0.16),
            AppColors.brandAccent.withOpacity(0.03),
          ],
        ).createShader(archRect),
    );
    final Paint frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = AppColors.brandPrimary.withOpacity(0.32);
    canvas.drawPath(arch, frame);
    canvas.drawLine(Offset(c.dx, archTop), Offset(c.dx, archBottom), frame);
    canvas.drawLine(Offset(c.dx - archHalf, c.dy - 0.06 * u),
        Offset(c.dx + archHalf, c.dy - 0.06 * u), frame);

    final Path beam = Path()
      ..moveTo(c.dx - archHalf, archBottom)
      ..lineTo(c.dx + archHalf, archBottom)
      ..lineTo(c.dx + archHalf - 0.12 * u, shelfY)
      ..lineTo(c.dx - archHalf - 0.3 * u, shelfY)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.brandAccent.withOpacity(0.12),
            AppColors.brandAccent.withOpacity(0.02),
          ],
        ).createShader(beam.getBounds()),
    );

    final Paint spineFill = Paint()
      ..color = AppColors.splashCharcoal.withOpacity(0.9);
    final Paint spineEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = AppColors.brandPrimary.withOpacity(0.3);
    final Paint band = Paint()
      ..strokeWidth = 0.7
      ..color = AppColors.brandAccent.withOpacity(0.35);
    final math.Random random = math.Random(7);
    double x = c.dx - 0.62 * u;
    final double end = math.min(c.dx + 0.62 * u, size.width - 0.04 * u);
    while (x < end) {
      final double width = (0.035 + random.nextDouble() * 0.035) * u;
      final double height = (0.16 + random.nextDouble() * 0.12) * u;
      final Rect spine = Rect.fromLTWH(x, shelfY - height, width, height);
      canvas.drawRect(spine, spineFill);
      canvas.drawRect(spine, spineEdge);
      if (random.nextDouble() > 0.55) {
        final double bandY = spine.top + height * 0.2;
        canvas.drawLine(Offset(spine.left + 1, bandY),
            Offset(spine.right - 1, bandY), band);
      }
      x += width + 0.006 * u;
    }
    canvas.drawLine(
      Offset(c.dx - 0.66 * u, shelfY),
      Offset(math.min(c.dx + 0.66 * u, size.width), shelfY),
      frame,
    );
  }

  @override
  bool shouldRepaint(covariant LibraryArchArt oldDelegate) => false;
}

/// Fine-line celestial dial with a small open book at its centre.
class CelestialDialArt extends CustomPainter {
  const CelestialDialArt();

  static const int _tickCount = 60;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = _artCenter(size);
    final double u = size.height;
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    const List<(double, double)> rings = [
      (0.2, 0.3),
      (0.3, 0.2),
      (0.42, 0.12),
    ];
    for (final (double radius, double opacity) in rings) {
      stroke.color = AppColors.brandPrimary.withOpacity(opacity);
      canvas.drawCircle(c, radius * u, stroke);
    }

    final double tickRadius = 0.3 * u;
    for (int i = 0; i < _tickCount; i++) {
      final double angle = i * 2 * math.pi / _tickCount;
      final bool major = i % 5 == 0;
      final Offset direction = Offset(math.cos(angle), math.sin(angle));
      stroke.color = AppColors.brandPrimary.withOpacity(major ? 0.32 : 0.16);
      canvas.drawLine(
        c + direction * tickRadius,
        c + direction * (tickRadius + (major ? 0.03 : 0.014) * u),
        stroke,
      );
    }

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.35);
    stroke.color = AppColors.brandAccent.withOpacity(0.14);
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 1.1 * u, height: 0.32 * u),
        stroke);
    canvas.restore();

    final Rect fragment = Rect.fromCircle(center: c, radius: 0.5 * u);
    stroke.color = AppColors.brandPrimary.withOpacity(0.1);
    canvas.drawArc(fragment, -math.pi * 0.9, math.pi * 0.4, false, stroke);
    canvas.drawArc(fragment, math.pi * 0.1, math.pi * 0.4, false, stroke);

    final Paint glow = Paint()
      ..color = AppColors.brandAccent.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    final Paint node = Paint()..color = AppColors.brandAccent.withOpacity(0.9);
    for (final double angle in const [-0.9, 2.4, 4.6]) {
      final Offset p =
          c + Offset(math.cos(angle), math.sin(angle)) * (0.42 * u);
      canvas.drawCircle(p, 2.6, glow);
      canvas.drawCircle(p, 1.2, node);
    }

    final double r = 0.1 * u;
    final Paint book = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..color = AppColors.brandAccent.withOpacity(0.8);
    final double top = c.dy - 0.15 * r;
    final double bottom = c.dy + 0.55 * r;
    for (final double side in const [-1.0, 1.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, top)
          ..quadraticBezierTo(
              c.dx + side * 0.5 * r, top - 0.2 * r, c.dx + side * r, top)
          ..lineTo(c.dx + side * r, bottom - 0.1 * r)
          ..quadraticBezierTo(
              c.dx + side * 0.5 * r, bottom - 0.25 * r, c.dx, bottom),
        book,
      );
    }
    canvas.drawLine(Offset(c.dx, top), Offset(c.dx, bottom), book);
    final double spark = 0.12 * r;
    final Offset sparkCenter = Offset(c.dx, top - 0.55 * r);
    canvas.drawPath(
      Path()
        ..moveTo(sparkCenter.dx, sparkCenter.dy - spark * 1.6)
        ..lineTo(sparkCenter.dx + spark, sparkCenter.dy)
        ..lineTo(sparkCenter.dx, sparkCenter.dy + spark * 1.6)
        ..lineTo(sparkCenter.dx - spark, sparkCenter.dy)
        ..close(),
      node,
    );
  }

  @override
  bool shouldRepaint(covariant CelestialDialArt oldDelegate) => false;
}
