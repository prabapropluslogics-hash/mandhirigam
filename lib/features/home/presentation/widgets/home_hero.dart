import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../data/models/app_config.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_gradients.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';

class HomeHero extends StatelessWidget {
  const HomeHero({super.key, required this.home, required this.appName});

  final HomeConfig home;
  final String appName;

  @override
  Widget build(BuildContext context) {
    final String title =
        home.heroTitle.trim().isEmpty ? appName : home.heroTitle.trim();
    final String subtitle = home.heroSubtitle.trim();

    return Padding(
      padding: AppInsets.pageHorizontal,
      child: ClipRRect(
        borderRadius: AppRadii.cardBorder,
        child: SizedBox(
          height: AppSizes.featuredCardHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (home.heroImageUrl != null && home.heroImageUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: home.heroImageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const DecoratedBox(
                    decoration: BoxDecoration(gradient: AppGradients.featured),
                  ),
                )
              else
                const DecoratedBox(
                  decoration: BoxDecoration(gradient: AppGradients.featured),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.transparent,
                      Color(0xCC0D0D0D),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: AppInsets.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bookTitle(
                        context,
                        fontSize: 28,
                        color: AppColors.neutral0,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.neutral200,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
