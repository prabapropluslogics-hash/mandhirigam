import 'package:flutter/material.dart';

import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/models/subscription_plan.dart';

class FeatureCheckRow extends StatelessWidget {
  const FeatureCheckRow({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            AppIcons.checkFilled,
            size: AppSizes.iconMd,
            color: Theme.of(context).colorScheme.primary,
          ),
          const AppGap.md(axis: AppGapAxis.horizontal),
          Expanded(
            child: Text(label, style: AppTypography.body(context)),
          ),
        ],
      ),
    );
  }
}

class PlanOptionCard extends StatelessWidget {
  const PlanOptionCard({
    super.key,
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Brightness brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: AppColors.surfaceMutedFor(brightness),
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.cardBorder,
              side: BorderSide(
                color: selected ? colors.primary : AppColors.borderDark,
                width: selected ? AppSizes.borderThick : AppSizes.borderThin,
              ),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadii.cardBorder,
              child: Padding(
                padding: AppInsets.lg,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.periodLabel,
                            style: AppTypography.sectionTitle(context),
                          ),
                          const AppGap.xs(),
                          Text(
                            '${plan.pricePerMonthLabel} · ${plan.billingLabel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.helper(context),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      Icon(
                        AppIcons.checkFilled,
                        color: colors.primary,
                        size: AppSizes.iconLg,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (plan.bestValue)
            Positioned(
              top: -10,
              left: AppSpacing.lg,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: AppRadii.chipBorder,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  child: Text(
                    'BEST VALUE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textOnBrand,
                          letterSpacing: 0.8,
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
