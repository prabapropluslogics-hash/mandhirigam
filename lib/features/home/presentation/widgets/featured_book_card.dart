import 'package:flutter/material.dart';

import '../../../../design_system/components/feedback/premium_badge.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_gradients.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/models/book.dart';

class FeaturedBookCard extends StatelessWidget {
  const FeaturedBookCard({
    super.key,
    required this.book,
    this.onTap,
  });

  final Book book;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppInsets.pageHorizontal,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.cardBorder,
          child: Ink(
            height: AppSizes.featuredCardHeight,
            decoration: BoxDecoration(
              gradient: AppGradients.featured,
              borderRadius: AppRadii.cardBorder,
            ),
            child: Padding(
              padding: AppInsets.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (book.isPremium)
                    const PremiumBadge(tone: PremiumBadgeTone.dark),
                  const Spacer(),
                  Text(
                    book.title,
                    style: AppTypography.bookTitle(
                      context,
                      fontSize: 26,
                      color: AppColors.neutral0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${book.author} · ${book.genre}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.neutral200,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
