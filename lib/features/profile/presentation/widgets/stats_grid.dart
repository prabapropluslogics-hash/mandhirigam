import 'package:flutter/material.dart';

import '../../../../design_system/components/layout/app_card.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTypography.bookTitle(context, fontSize: 28),
          ),
          const AppGap.xs(),
          Text(label, style: AppTypography.helper(context)),
        ],
      ),
    );
  }
}

class StatsGrid extends StatelessWidget {
  const StatsGrid({
    super.key,
    required this.booksRead,
    required this.dayStreak,
    required this.timeReading,
    required this.pagesTurned,
  });

  final String booksRead;
  final String dayStreak;
  final String timeReading;
  final String pagesTurned;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppInsets.pageHorizontal,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(value: booksRead, label: 'Books read'),
              ),
              const AppGap.md(axis: AppGapAxis.horizontal),
              Expanded(
                child: StatCard(value: dayStreak, label: 'Day streak'),
              ),
            ],
          ),
          const AppGap.md(),
          Row(
            children: [
              Expanded(
                child: StatCard(value: timeReading, label: 'Time reading'),
              ),
              const AppGap.md(axis: AppGapAxis.horizontal),
              Expanded(
                child: StatCard(value: pagesTurned, label: 'Pages turned'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
