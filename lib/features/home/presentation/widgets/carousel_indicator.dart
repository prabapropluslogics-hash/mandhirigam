import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';

/// Minimal dot indicator: the active dot is slightly larger and brighter.
class CarouselIndicator extends StatelessWidget {
  const CarouselIndicator({
    super.key,
    required this.count,
    required this.activeIndex,
  });

  final int count;
  final int activeIndex;

  static const double _dot = 5;
  static const double _activeDot = 7;
  static const double _gap = 3;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: _activeDot,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: _gap),
                width: i == activeIndex ? _activeDot : _dot,
                height: i == activeIndex ? _activeDot : _dot,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == activeIndex
                      ? AppColors.brandAccent.withOpacity(0.9)
                      : AppColors.brandPrimary.withOpacity(0.28),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
