import 'package:flutter/material.dart';

import '../../design_system/theme/app_colors.dart';
import '../../design_system/theme/app_radii.dart';

class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius,
  });

  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      return _box(AppColors.surfaceElevatedDark);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return _box(
          Color.lerp(
            AppColors.surfaceMutedDark,
            AppColors.surfaceElevatedDark,
            (_controller.value < 0.5
                    ? _controller.value
                    : 1 - _controller.value) *
                2,
          )!,
        );
      },
    );
  }

  Widget _box(Color color) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: widget.borderRadius ?? AppRadii.cardBorder,
      ),
    );
  }
}
