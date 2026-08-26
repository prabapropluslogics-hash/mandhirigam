import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Reusable gradients from the UI reference.
abstract final class AppGradients {
  static const LinearGradient featured = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      AppColors.featuredStart,
      AppColors.featuredMid,
      AppColors.featuredEnd,
    ],
    stops: <double>[0.0, 0.45, 1.0],
  );
}
