import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';

/// Shared editorial card shell for Home carousels: rounded corners, a soft
/// drop shadow, a gold hairline border and an optional full-card ripple drawn
/// above the (often opaque) content.
class HomeCardFrame extends StatelessWidget {
  const HomeCardFrame({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(AppRadii.lg);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowWithOpacity(0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: AppColors.brandPrimary.withOpacity(0.16),
                    width: AppSizes.borderThin,
                  ),
                ),
              ),
            ),
            if (onTap != null)
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                  child: Semantics(button: true, label: semanticLabel),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
