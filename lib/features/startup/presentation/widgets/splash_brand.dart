import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';

/// Thin-line emblem above the wordmark: an open book inside a celestial ring,
/// with a small point of light above the spine.
class SplashEmblem extends StatelessWidget {
  const SplashEmblem({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: const CustomPaint(painter: _EmblemPainter()),
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.shortestSide / 2 - 1;
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    stroke
      ..strokeWidth = 0.8
      ..color = AppColors.brandPrimary.withOpacity(0.55);
    canvas.drawCircle(c, r, stroke);
    stroke
      ..strokeWidth = 0.5
      ..color = AppColors.brandPrimary.withOpacity(0.25);
    canvas.drawCircle(c, r * 0.84, stroke);

    for (int i = 0; i < 4; i++) {
      final double angle = i * math.pi / 2;
      final Offset direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(c + direction * r * 0.84, c + direction * r, stroke);
    }

    final double top = c.dy - r * 0.12;
    final double bottom = c.dy + r * 0.40;
    final double edge = r * 0.50;
    final Path book = Path()
      ..moveTo(c.dx, top)
      ..quadraticBezierTo(c.dx - edge * 0.5, top - r * 0.14, c.dx - edge, top - r * 0.04)
      ..lineTo(c.dx - edge, bottom - r * 0.10)
      ..quadraticBezierTo(c.dx - edge * 0.5, bottom - r * 0.20, c.dx, bottom)
      ..quadraticBezierTo(c.dx + edge * 0.5, bottom - r * 0.20, c.dx + edge, bottom - r * 0.10)
      ..lineTo(c.dx + edge, top - r * 0.04)
      ..quadraticBezierTo(c.dx + edge * 0.5, top - r * 0.14, c.dx, top)
      ..lineTo(c.dx, bottom);
    stroke
      ..strokeWidth = 1
      ..color = AppColors.brandAccent.withOpacity(0.85);
    canvas.drawPath(book, stroke);

    final double spark = r * 0.07;
    final Offset sparkCenter = Offset(c.dx, c.dy - r * 0.46);
    final Path diamond = Path()
      ..moveTo(sparkCenter.dx, sparkCenter.dy - spark * 1.6)
      ..lineTo(sparkCenter.dx + spark, sparkCenter.dy)
      ..lineTo(sparkCenter.dx, sparkCenter.dy + spark * 1.6)
      ..lineTo(sparkCenter.dx - spark, sparkCenter.dy)
      ..close();
    canvas.drawPath(
      diamond,
      Paint()..color = AppColors.brandAccent.withOpacity(0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _EmblemPainter oldDelegate) => false;
}

/// "MAANTHIRIGAM" in a serif with wide tracking and a muted gold finish.
/// Scales down rather than overflowing on narrow screens.
class SplashTitle extends StatelessWidget {
  const SplashTitle({super.key, this.fontSize = 30});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final double tracking = fontSize * 0.24;
    final TextStyle style = AppTypography.bookTitle(
      context,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: AppColors.brandAccent,
    ).copyWith(letterSpacing: tracking, height: 1.1);

    return Semantics(
      header: true,
      label: AppConstants.appName,
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (Rect bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.brandAccent,
                AppColors.brandPrimary,
                AppColors.brandSecondary,
              ],
              stops: [0, 0.55, 1],
            ).createShader(bounds),
            // Letter spacing trails the last glyph; leading pad re-centres it.
            child: Padding(
              padding: EdgeInsets.only(left: tracking),
              child: Text(
                AppConstants.appName.toUpperCase(),
                style: style,
                maxLines: 1,
                softWrap: false,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Hairline – diamond – hairline divider between title and tagline.
class SplashOrnament extends StatelessWidget {
  const SplashOrnament({super.key, this.lineWidth = 40});

  final double lineWidth;

  @override
  Widget build(BuildContext context) {
    final Color gold = AppColors.brandPrimary.withOpacity(0.6);
    Widget hairline(Alignment from) => SizedBox(
          width: lineWidth,
          height: 0.8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: from,
                end: -from,
                colors: [gold.withOpacity(0), gold],
              ),
            ),
          ),
        );

    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          hairline(Alignment.centerLeft),
          const SizedBox(width: AppSpacing.sm),
          Transform.rotate(
            angle: math.pi / 4,
            child: SizedBox.square(
              dimension: AppSpacing.xs,
              child: ColoredBox(color: gold),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          hairline(Alignment.centerRight),
        ],
      ),
    );
  }
}

/// Final product tagline, set small in soft warm white.
class SplashTagline extends StatelessWidget {
  const SplashTagline({super.key});

  static const String text = 'Beyond the Seen, Into the Unknown';

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodySmall(context).copyWith(
        color: AppColors.splashTagline.withOpacity(0.72),
        fontWeight: FontWeight.w300,
        letterSpacing: 1.4,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }
}
