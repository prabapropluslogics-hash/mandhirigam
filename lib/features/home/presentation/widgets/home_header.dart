import 'package:flutter/material.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../startup/presentation/widgets/splash_brand.dart';

/// Greeting line over the gold MAANTHIRIGAM wordmark, with the splash emblem
/// as a quiet brand mark on the right.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.greeting});

  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppInsets.pageHorizontal,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall(context).copyWith(
                    color: AppColors.textSecondaryDark,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: SplashTitle(fontSize: 22),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPrimary.withOpacity(0.18),
                  blurRadius: 18,
                ),
              ],
            ),
            child: const SplashEmblem(size: 40),
          ),
        ],
      ),
    );
  }
}
