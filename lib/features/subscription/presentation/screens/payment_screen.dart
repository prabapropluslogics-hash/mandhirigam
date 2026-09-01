import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/buttons/app_button_shared.dart';
import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/buttons/app_text_button.dart';
import '../../../../design_system/components/inputs/app_text_field.dart';
import '../../../../design_system/components/layout/app_docked_footer.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/components/navigation/app_segmented_control.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../routing/app_router.dart';
import '../../../../shared/data/mock_catalog.dart';
import '../../../../shared/models/subscription_plan.dart';
import '../widgets/order_summary_card.dart';

enum PaymentMethod { card, applePay, googlePay }

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.planId});

  final String planId;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _method = PaymentMethod.card;
  late final TextEditingController _cardController =
      TextEditingController(text: '4242 4242 4242 4242');
  late final TextEditingController _expiryController =
      TextEditingController(text: '08 / 28');
  late final TextEditingController _cvvController =
      TextEditingController(text: '•••');
  late final TextEditingController _nameController =
      TextEditingController(text: MockCatalog.currentUserName);
  late final TextEditingController _promoController = TextEditingController();

  @override
  void dispose() {
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SubscriptionPlan plan = MockCatalog.planById(widget.planId);

    return AppScaffold(
      safeAreaBottom: false,
      body: Column(
        children: [
          Padding(
            padding: AppInsets.pageHorizontal,
            child: Row(
              children: [
                AppIconButton(
                  icon: AppIcons.back,
                  tooltip: 'Back',
                  onPressed: () => AppRouter.pop(context),
                ),
                Expanded(
                  child: Text(
                    'Payment',
                    style: AppTypography.bookTitle(context, fontSize: 22),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: AppInsets.pageHorizontal,
              children: [
                const AppGap.lg(),
                OrderSummaryCard(plan: plan),
                const AppGap.xxl(),
                Text(
                  'PAYMENT METHOD',
                  style: AppTypography.caption(context).copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const AppGap.md(),
                AppSegmentedControl<PaymentMethod>(
                  selected: _method,
                  onChanged: (PaymentMethod value) {
                    setState(() => _method = value);
                  },
                  items: const <AppSegmentItem<PaymentMethod>>[
                    AppSegmentItem<PaymentMethod>(
                      value: PaymentMethod.card,
                      label: 'Card',
                    ),
                    AppSegmentItem<PaymentMethod>(
                      value: PaymentMethod.applePay,
                      label: 'Pay',
                      icon: AppIcons.apple,
                    ),
                    AppSegmentItem<PaymentMethod>(
                      value: PaymentMethod.googlePay,
                      label: 'G Pay',
                    ),
                  ],
                ),
                if (_method == PaymentMethod.card) ...[
                  const AppGap.lg(),
                  AppTextField(
                    controller: _cardController,
                    hintText: 'Card number',
                    keyboardType: TextInputType.number,
                    suffixIcon: const Icon(
                      AppIcons.creditCard,
                      size: AppSizes.iconMd,
                    ),
                  ),
                  const AppGap.md(),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _expiryController,
                          hintText: 'Expiry',
                          keyboardType: TextInputType.datetime,
                        ),
                      ),
                      const AppGap.md(axis: AppGapAxis.horizontal),
                      Expanded(
                        child: AppTextField(
                          controller: _cvvController,
                          hintText: 'CVV',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const AppGap.md(),
                  AppTextField(
                    controller: _nameController,
                    hintText: 'Name on card',
                    textInputAction: TextInputAction.next,
                  ),
                  const AppGap.md(),
                  AppTextField(
                    controller: _promoController,
                    hintText: 'Promo code',
                    suffixIcon: AppTextButton(
                      label: 'Apply',
                      compact: true,
                      onPressed: () {},
                    ),
                  ),
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
                  label: 'Confirm & pay ${plan.totalLabel}',
                  size: AppButtonSize.large,
                  gradient: true,
                  leadingIcon: AppIcons.lock,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    AppRouter.pop(context);
                  },
                ),
                const AppGap.sm(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      AppIcons.lockOutline,
                      size: AppSizes.iconXs,
                      color: AppColors.textSecondaryDark,
                    ),
                    const AppGap.xs(axis: AppGapAxis.horizontal),
                    Flexible(
                      child: Text(
                        'Secured with 256-bit encryption',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
