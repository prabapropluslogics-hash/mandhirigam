import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_sizes.dart';
import '../../theme/app_spacing.dart';

/// Star + numeric rating, optionally with a review count.
class RatingView extends StatelessWidget {
  const RatingView({
    super.key,
    required this.rating,
    this.reviewCountLabel,
    this.compact = false,
  });

  final double rating;
  final String? reviewCountLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String label = reviewCountLabel == null
        ? rating.toStringAsFixed(1)
        : '${rating.toStringAsFixed(1)} ($reviewCountLabel)';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          AppIcons.star,
          size: compact ? AppSizes.iconSm : AppSizes.iconMd,
          color: colors.primary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: compact
              ? Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  )
              : Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}
