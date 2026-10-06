import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_spacing.dart';
import 'splash_backdrop.dart';

/// Full-screen splash shell: [SplashBackdrop] behind a safe, centred column
/// that scrolls instead of overflowing on short (e.g. landscape) screens.
class SplashFrame extends StatelessWidget {
  const SplashFrame({super.key, required this.progress, required this.child});

  final Animation<double> progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        SplashBackdrop(progress: progress),
        SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: AppInsets.page,
                    child: Center(child: child),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
