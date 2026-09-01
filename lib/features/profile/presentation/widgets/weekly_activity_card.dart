import 'package:flutter/material.dart';

import '../../../../design_system/components/layout/app_card.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/models/profile_stats.dart';

class WeeklyActivityCard extends StatelessWidget {
  const WeeklyActivityCard({super.key, required this.activity});

  final WeeklyActivity activity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppInsets.pageHorizontal,
      child: AppCard(
        child: SizedBox(
          height: AppSizes.chartBarMaxHeight + AppSpacing.xxl,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (int i = 0; i < activity.values.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _DayBar(
                    value: activity.values[i],
                    label: activity.dayLabels[i],
                    highlighted: i == activity.highlightedIndex,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.value,
    required this.label,
    required this.highlighted,
  });

  final double value;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final Color barColor =
        highlighted ? AppColors.brandPrimary : AppColors.neutral600;
    final Color labelColor =
        highlighted ? AppColors.brandPrimary : AppColors.textSecondaryDark;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: AppSizes.chartBarWidth,
                  height: constraints.maxHeight * value.clamp(0.08, 1),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(AppRadii.full),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            label,
            style: AppTypography.caption(context).copyWith(color: labelColor),
          ),
        ),
      ],
    );
  }
}
