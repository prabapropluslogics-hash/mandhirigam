import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import 'home_banner_art.dart';
import 'home_card_frame.dart';
import 'home_carousel.dart';

/// Brand banner at the top of Home: auto-advancing atmosphere slides about
/// the reading experience. Never shows catalogue books.
class HomeBanner extends StatelessWidget {
  const HomeBanner({super.key});

  static const List<HomeBannerSlideData> slides = [
    HomeBannerSlideData(
      title: 'Enter a World Beyond the Visible',
      art: OpenBookLightArt(),
      glowCenter: Alignment(0.45, -0.35),
    ),
    HomeBannerSlideData(
      title: 'Ancient Knowledge. New Perspective.',
      art: PalmLeafArt(),
      glowCenter: Alignment(0.5, 0),
    ),
    HomeBannerSlideData(
      title: 'Stories of Mystery, Knowledge & the Unknown',
      art: LibraryArchArt(),
      glowCenter: Alignment(0.45, -0.3),
    ),
    HomeBannerSlideData(
      title: 'Discover. Read. Explore.',
      art: CelestialDialArt(),
      glowCenter: Alignment(0.45, 0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return HomeCarousel(
      itemCount: slides.length,
      heightFactor: 0.54,
      minHeight: 180,
      maxHeight: 260,
      textScaleAllowance: 60,
      itemBuilder: (BuildContext context, int index) {
        return HomeBannerSlide(data: slides[index]);
      },
    );
  }
}

@immutable
class HomeBannerSlideData {
  const HomeBannerSlideData({
    required this.title,
    required this.art,
    required this.glowCenter,
  });

  final String title;
  final CustomPainter art;
  final Alignment glowCenter;
}

/// One banner slide: obsidian base, warm glow behind the artwork, a scrim
/// that keeps the left-side copy legible, then the brand line and title.
class HomeBannerSlide extends StatelessWidget {
  const HomeBannerSlide({super.key, required this.data});

  final HomeBannerSlideData data;

  @override
  Widget build(BuildContext context) {
    return HomeCardFrame(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double titleSize =
              (constraints.maxWidth / 17).clamp(18.0, 24.0);
          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.splashCharcoal,
                      AppColors.splashBase,
                      AppColors.splashDeep,
                    ],
                    stops: [0, 0.55, 1],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: data.glowCenter,
                    radius: 0.9,
                    colors: [
                      AppColors.splashGlow.withOpacity(0.24),
                      AppColors.splashGlow.withOpacity(0.06),
                      AppColors.splashGlow.withOpacity(0),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
              ExcludeSemantics(child: CustomPaint(painter: data.art)),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.splashBase.withOpacity(0.88),
                      AppColors.splashBase.withOpacity(0.45),
                      AppColors.splashBase.withOpacity(0),
                    ],
                    stops: const [0, 0.42, 0.7],
                  ),
                ),
              ),
              Padding(
                padding: AppInsets.lg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const _BrandLine(),
                    const SizedBox(height: AppSpacing.sm),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.58,
                        ),
                        child: Text(
                          data.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bookTitle(
                            context,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimaryDark,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandLine extends StatelessWidget {
  const _BrandLine();

  @override
  Widget build(BuildContext context) {
    final Color gold = AppColors.brandAccent.withOpacity(0.85);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: AppSpacing.lg,
          height: 1,
          child: ColoredBox(color: gold),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            AppConstants.appName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: gold,
                  letterSpacing: 2,
                ),
          ),
        ),
      ],
    );
  }
}
