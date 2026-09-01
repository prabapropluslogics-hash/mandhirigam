import 'package:flutter/material.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/buttons/app_button_shared.dart';
import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/layout/app_docked_footer.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../routing/app_router.dart';
import '../../../../routing/app_routes.dart';
import '../../../../shared/data/mock_catalog.dart';
import '../../../../shared/models/subscription_plan.dart';
import '../widgets/plan_option_card.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  String _selectedId = MockCatalog.annualPlan.id;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return AppScaffold(
      safeAreaBottom: false,
      body: Column(
        children: [
          Padding(
            padding: AppInsets.pageHorizontal,
            child: Align(
              alignment: Alignment.centerRight,
              child: AppIconButton(
                icon: AppIcons.close,
                tooltip: 'Close',
                onPressed: () => AppRouter.pop(context),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: AppInsets.pageHorizontal,
              children: [
                const AppGap.lg(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMutedDark,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Padding(
                      padding: AppInsets.md,
                      child: Icon(
                        AppIcons.premium,
                        color: colors.primary,
                        size: AppSizes.iconXl,
                      ),
                    ),
                  ),
                ),
                const AppGap.xl(),
                Text(
                  'Unlock every story',
                  style: AppTypography.bookTitle(context, fontSize: 32),
                ),
                const AppGap.sm(),
                Text(
                  'Full access to ${MockCatalog.catalogBrand}\'s premium library, '
                  'offline reading, and early releases.',
                  style: AppTypography.helper(context),
                ),
                const AppGap.xxl(),
                for (final String feature in MockCatalog.subscriptionFeatures)
                  FeatureCheckRow(label: feature),
                const AppGap.lg(),
                for (final SubscriptionPlan plan in MockCatalog.plans) ...[
                  PlanOptionCard(
                    plan: plan,
                    selected: plan.id == _selectedId,
                    onTap: () => setState(() => _selectedId = plan.id),
                  ),
                  const AppGap.md(),
                ],
                const AppGap.xxl(),
              ],
            ),
          ),
          AppDockedFooter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  label: 'Continue',
                  size: AppButtonSize.large,
                  gradient: true,
                  onPressed: () {
                    AppRouter.pushNamed(
                      context,
                      AppRoutes.payment,
                      arguments: _selectedId,
                    );
                  },
                ),
                const AppGap.sm(),
                Text(
                  'Cancel anytime. Auto-renews until cancelled.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption(context),
                ),
                AppTextButton(
                  label: 'Restore purchase',
                  compact: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
