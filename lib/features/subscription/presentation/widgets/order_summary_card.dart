import 'package:flutter/material.dart';

import '../../../../design_system/components/layout/app_card.dart';
import '../../../../design_system/components/layout/app_divider.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_key_value_row.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../shared/models/subscription_plan.dart';

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, required this.plan});

  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          AppKeyValueRow(label: 'Plan', value: plan.displayName),
          const AppGap.md(),
          AppKeyValueRow(label: 'Subtotal', value: plan.subtotalLabel),
          const AppGap.md(),
          AppKeyValueRow(label: 'Tax', value: plan.taxLabel),
          const AppDivider(space: AppSpacing.xxl),
          AppKeyValueRow(
            label: 'Total due today',
            labelStyle: AppTypography.body(context),
            value: plan.totalLabel,
            valueStyle: AppTypography.bookTitle(
              context,
              fontSize: 22,
              color: AppColors.brandPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
