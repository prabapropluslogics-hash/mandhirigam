import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';

/// Decorative reader illustration with feathered edges so it dissolves into
/// the charcoal backdrop at any size.
class LoginHero extends StatelessWidget {
  const LoginHero({super.key, required this.height, required this.maxWidth});

  static const String asset = 'assets/images/login_reader.jpg';

  /// Native pixel size of [asset].
  static const Size _sourceSize = Size(864, 1152);

  /// How much wider than the artwork's own aspect the frame may grow; the
  /// excess is cropped from the (empty) top and bottom margins.
  static const double _maxCropWidening = 1.2;

  final double height;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final double aspect = _sourceSize.width / _sourceSize.height;
    final double width = math.min(maxWidth, height * aspect * _maxCropWidening);
    final double paintedHeight = math.max(height, width / aspect);
    final int cacheHeight = math.min(
      (paintedHeight * MediaQuery.devicePixelRatioOf(context)).round(),
      _sourceSize.height.toInt(),
    );

    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: height,
        child: RepaintBoundary(
          child: _Feather(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.14, 0.8, 1],
            child: _Feather(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0, 0.18, 0.82, 1],
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.3),
                cacheHeight: cacheHeight,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades [child] to transparent at both ends of one axis.
class _Feather extends StatelessWidget {
  const _Feather({
    required this.begin,
    required this.end,
    required this.stops,
    required this.child,
  });

  final Alignment begin;
  final Alignment end;
  final List<double> stops;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const Color opaque = AppColors.shadow;
    final Color clear = AppColors.shadow.withOpacity(0);
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (Rect bounds) => LinearGradient(
        begin: begin,
        end: end,
        colors: [clear, opaque, opaque, clear],
        stops: stops,
      ).createShader(bounds),
      child: child,
    );
  }
}
