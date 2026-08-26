import 'package:flutter/material.dart';

import '../../theme/app_sizes.dart';

/// Shared circular progress indicator for inline and full-page loading.
class AppLoader extends StatelessWidget {
  const AppLoader({
    super.key,
    this.size = AppSizes.iconXl,
    this.strokeWidth = AppSizes.loaderStrokeWidth,
    this.color,
  });

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// Full-page centered [AppLoader].
class AppLoaderPage extends StatelessWidget {
  const AppLoaderPage({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Center(child: AppLoader(color: color));
  }
}
