import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../reader_palette.dart';

/// Flat page tone with faint palm-leaf fibres (Olaichuvadi). Used for small
/// previews; the reader itself uses [ReaderSurface].
class ReaderPaper extends StatelessWidget {
  const ReaderPaper({super.key, required this.palette});

  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[palette.background, palette.backgroundEnd],
          ),
        ),
        child: palette.manuscript
            ? const CustomPaint(
                painter: _FibrePainter(),
                child: SizedBox.expand(),
              )
            : const SizedBox.expand(),
      ),
    );
  }
}

/// The reading sheet. Olaichuvadi: aged parchment with burnt, slightly
/// uneven edges, rolled ends and a faint palm frond. Dark and Light: a
/// rounded page with a fine rule. [child] is clipped clear of the edges and
/// fades softly at the top and bottom.
class ReaderSurface extends StatelessWidget {
  const ReaderSurface({super.key, required this.palette, required this.child});

  /// Space kept free of text at the top and bottom of the sheet.
  static const double edge = 16;
  static const double _fade = 16;

  final ReaderPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: palette.manuscript
                  ? const _OlaiSheetPainter()
                  : _PlainSheetPainter(palette),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        Positioned.fill(
          top: edge,
          bottom: edge,
          child: ClipRect(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (Rect bounds) {
                final double stop =
                    bounds.height <= _fade * 2 ? 0 : _fade / bounds.height;
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const <Color>[
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: <double>[0, stop, 1 - stop, 1],
                ).createShader(bounds);
              },
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

class _OlaiSheetPainter extends CustomPainter {
  const _OlaiSheetPainter();

  static const double _inset = 3;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 60 || size.height < 60) return;
    final Path sheet = _unevenEdge(size);
    final Rect bounds = Offset.zero & size;

    canvas.drawShadow(sheet, Colors.black, 10, false);
    canvas.drawPath(
      sheet,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.1, -0.25),
          radius: 1.05,
          colors: <Color>[
            AppColors.readerParchment,
            AppColors.readerParchmentDeep,
            AppColors.readerParchmentEdge,
          ],
          stops: <double>[0.2, 0.72, 1],
        ).createShader(bounds),
    );

    canvas.save();
    canvas.clipPath(sheet);
    _stains(canvas, size);
    _FibrePainter.paintFibres(canvas, size);
    _rolledEnds(canvas, size);
    _frond(canvas, size);
    canvas.drawPath(
      sheet,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 34
        ..color = AppColors.readerBurn.withOpacity(0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawPath(
      sheet,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = AppColors.readerBurn.withOpacity(0.7)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.restore();

    canvas.drawPath(
      sheet,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color = AppColors.readerBurn.withOpacity(0.75),
    );
  }

  /// A rectangle whose sides wander by a couple of pixels, like a trimmed,
  /// aged sheet. Deterministic, so it never shimmers between frames.
  static Path _unevenEdge(Size size) {
    final math.Random random = math.Random(1729);
    final List<double> phase =
        List<double>.generate(8, (_) => random.nextDouble() * math.pi * 2);
    double wobble(double t, int side) =>
        1.2 +
        0.9 * math.sin(t * 7.0 + phase[side]) +
        0.6 * math.sin(t * 19.0 + phase[side + 4]);

    final double w = size.width;
    final double h = size.height;
    const double step = 6;
    final Path path = Path()..moveTo(_inset + 2, _inset + wobble(0, 0));
    for (double x = _inset + 2; x <= w - _inset - 2; x += step) {
      path.lineTo(x, _inset + wobble(x / w, 0));
    }
    for (double y = _inset + 2; y <= h - _inset - 2; y += step) {
      path.lineTo(w - _inset - wobble(y / h, 1), y);
    }
    for (double x = w - _inset - 2; x >= _inset + 2; x -= step) {
      path.lineTo(x, h - _inset - wobble(x / w, 2));
    }
    for (double y = h - _inset - 2; y >= _inset + 2; y -= step) {
      path.lineTo(_inset + wobble(y / h, 3), y);
    }
    return path..close();
  }

  static void _stains(Canvas canvas, Size size) {
    final math.Random random = math.Random(311);
    for (int i = 0; i < 9; i++) {
      final Offset centre = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final double radius =
          size.shortestSide * (0.12 + random.nextDouble() * 0.22);
      canvas.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              AppColors.readerStain.withOpacity(0.14),
              AppColors.readerStain.withOpacity(0),
            ],
          ).createShader(Rect.fromCircle(center: centre, radius: radius)),
      );
    }
  }

  /// Darker bands with a soft highlight at the top and bottom, suggesting
  /// the sheet is rolled at both ends.
  static void _rolledEnds(Canvas canvas, Size size) {
    const double band = 22;
    for (final bool top in <bool>[true, false]) {
      final Rect rect = top
          ? Rect.fromLTWH(0, 0, size.width, band)
          : Rect.fromLTWH(0, size.height - band, size.width, band);
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: top ? Alignment.topCenter : Alignment.bottomCenter,
            end: top ? Alignment.bottomCenter : Alignment.topCenter,
            colors: <Color>[
              AppColors.readerBurn.withOpacity(0.30),
              AppColors.readerBurn.withOpacity(0.08),
              AppColors.readerBurn.withOpacity(0),
            ],
            stops: const <double>[0, 0.55, 1],
          ).createShader(rect),
      );
      final double y = top ? band * 0.62 : size.height - band * 0.62;
      canvas.drawLine(
        Offset(10, y),
        Offset(size.width - 10, y),
        Paint()
          ..strokeWidth = 1
          ..color = AppColors.readerParchment.withOpacity(0.45),
      );
      canvas.drawLine(
        Offset(10, y + (top ? 2 : -2)),
        Offset(size.width - 10, y + (top ? 2 : -2)),
        Paint()
          ..strokeWidth = 0.8
          ..color = AppColors.readerBurn.withOpacity(0.16),
      );
    }
  }

  /// A faint palm frond rising from the lower-right corner.
  static void _frond(Canvas canvas, Size size) {
    final double span = math.min(size.width * 0.46, 210);
    final Offset base = Offset(size.width - 14, size.height - 12);
    final Offset control =
        Offset(size.width - span * 0.25, size.height - span * 0.75);
    final Offset tip = Offset(size.width - span, size.height - span * 1.05);
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = AppColors.readerFibre.withOpacity(0.2);

    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(control.dx, control.dy, tip.dx, tip.dy),
      stroke..strokeWidth = 1.4,
    );

    Offset at(double t) {
      final double u = 1 - t;
      return base * (u * u) + control * (2 * u * t) + tip * (t * t);
    }

    stroke.strokeWidth = 0.9;
    for (double t = 0.12; t < 0.97; t += 0.045) {
      final Offset point = at(t);
      final Offset ahead = at(math.min(t + 0.02, 1));
      final double angle = math.atan2(ahead.dy - point.dy, ahead.dx - point.dx);
      final double length = span * 0.3 * (1 - t * 0.65);
      for (final int side in <int>[-1, 1]) {
        final double leafAngle = angle + side * 0.75;
        final Offset end =
            point + Offset(math.cos(leafAngle), math.sin(leafAngle)) * length;
        final Offset bend = point +
            Offset(
                  math.cos(leafAngle + side * 0.25),
                  math.sin(leafAngle + side * 0.25),
                ) *
                (length * 0.55);
        canvas.drawPath(
          Path()
            ..moveTo(point.dx, point.dy)
            ..quadraticBezierTo(bend.dx, bend.dy, end.dx, end.dy),
          stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_OlaiSheetPainter oldDelegate) => false;
}

class _PlainSheetPainter extends CustomPainter {
  const _PlainSheetPainter(this.palette);

  final ReaderPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final Rect bounds = (Offset.zero & size).deflate(2);
    final RRect sheet =
        RRect.fromRectAndRadius(bounds, const Radius.circular(14));
    canvas.drawShadow(Path()..addRRect(sheet), Colors.black, 8, false);
    canvas.drawRRect(
      sheet,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[palette.background, palette.backgroundEnd],
        ).createShader(bounds),
    );
    canvas.drawRRect(
      sheet,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = palette.rule.withOpacity(0.35),
    );
  }

  @override
  bool shouldRepaint(_PlainSheetPainter oldDelegate) =>
      oldDelegate.palette.mode != palette.mode;
}

/// Deterministic horizontal fibres and specks, like the grain of a dried
/// palm leaf.
class _FibrePainter extends CustomPainter {
  const _FibrePainter();

  static void paintFibres(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final math.Random random = math.Random(1947);
    final Paint paint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final int fibres = (size.width * size.height / 1800).clamp(60, 520).toInt();
    for (int i = 0; i < fibres; i++) {
      final double y = random.nextDouble() * size.height;
      final double x = random.nextDouble() * size.width;
      final double length = 24 + random.nextDouble() * 140;
      paint
        ..strokeWidth = 0.4 + random.nextDouble() * 0.9
        ..color = AppColors.readerFibre
            .withOpacity(0.018 + random.nextDouble() * 0.035);
      final double drift = (random.nextDouble() - 0.5) * 1.6;
      canvas.drawLine(Offset(x, y), Offset(x + length, y + drift), paint);
    }
    final Paint speck = Paint()..style = PaintingStyle.fill;
    final int specks = (size.width * size.height / 2600).clamp(40, 360).toInt();
    for (int i = 0; i < specks; i++) {
      speck.color =
          AppColors.readerFibre.withOpacity(0.03 + random.nextDouble() * 0.05);
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        0.3 + random.nextDouble() * 0.7,
        speck,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) => paintFibres(canvas, size);

  @override
  bool shouldRepaint(_FibrePainter oldDelegate) => false;
}
