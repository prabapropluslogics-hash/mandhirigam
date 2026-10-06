import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// One-shot entrance timeline for the splash. Purely visual — it owns no
/// startup logic and never delays navigation.
class SplashIntro extends StatefulWidget {
  const SplashIntro({super.key, required this.builder});

  final Widget Function(BuildContext context, Animation<double> progress)
      builder;

  static const Duration duration = Duration(milliseconds: 2200);

  @override
  State<SplashIntro> createState() => _SplashIntroState();
}

class _SplashIntroState extends State<SplashIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: SplashIntro.duration,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

/// Fades [child] in over the `[begin, end]` slice of [progress], optionally
/// settling from a slight [scaleFrom] to full size.
class SplashReveal extends StatelessWidget {
  const SplashReveal({
    super.key,
    required this.progress,
    required this.begin,
    required this.end,
    this.scaleFrom = 1,
    required this.child,
  });

  final Animation<double> progress;
  final double begin;
  final double end;
  final double scaleFrom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Interval interval = Interval(begin, end, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (BuildContext context, Widget? child) {
        final double t = interval.transform(progress.value);
        Widget result = Opacity(opacity: t, child: child);
        if (scaleFrom != 1) {
          result = Transform.scale(
            scale: lerpDouble(scaleFrom, 1, t)!,
            child: result,
          );
        }
        return result;
      },
    );
  }
}
