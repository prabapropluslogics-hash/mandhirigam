import 'package:flutter/material.dart';

import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_radii.dart';
import '../../../../design_system/theme/app_sizes.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../state/payment_controller.dart';

/// Non-dismissible progress card shown while a purchase is creating the
/// order, in checkout, or being verified. Purely presentational: it follows
/// [PaymentController.phase] and never changes it.
class PaymentProgressDialog extends StatelessWidget {
  const PaymentProgressDialog({
    super.key,
    required this.payment,
    required this.bookTitle,
  });

  final PaymentController payment;
  final String bookTitle;

  /// Pushes the dialog and returns its route so the caller can remove it.
  static Route<void> show(
    BuildContext context, {
    required PaymentController payment,
    required String bookTitle,
  }) {
    final Route<void> route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.overlay,
      builder: (_) => PaymentProgressDialog(
        payment: payment,
        bookTitle: bookTitle,
      ),
    );
    Navigator.of(context).push(route);
    return route;
  }

  static void dismiss(Route<void> route) {
    if (!route.isActive) return;
    route.navigator?.removeRoute(route);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Material(
            color: AppColors.surfaceDark,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadii.dialogBorder,
              side: BorderSide(color: AppColors.brandPrimary.withOpacity(0.22)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xxl,
                AppSpacing.xxl,
                AppSpacing.xl,
              ),
              child: AnimatedBuilder(
                animation: payment,
                builder: (BuildContext context, _) => _content(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final PaymentPhase phase = payment.phase;
    final int step = switch (phase) {
      PaymentPhase.creatingOrder => 0,
      PaymentPhase.checkout => 1,
      _ => 2,
    };
    final (String title, String message) = switch (step) {
      0 => (
          'Creating secure order',
          'Preparing your purchase of $bookTitle.',
        ),
      1 => (
          'Opening checkout',
          'Complete the payment in the Razorpay window.',
        ),
      _ => (
          'Verifying payment',
          'Confirming with the server. Please keep the app open.',
        ),
    };
    final bool testMode =
        payment.lastOrder?.keyId.startsWith('rzp_test_') ?? false;

    return Semantics(
      liveRegion: true,
      label: title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.loaderStrokeWidth,
              color: AppColors.brandPrimary,
            ),
          ),
          const AppGap.xl(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Column(
              key: ValueKey<int>(step),
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.bookTitle(
                    context,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const AppGap.sm(),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall(context).copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
          const AppGap.xl(),
          _Steps(current: step),
          if (testMode) ...[
            const AppGap.lg(),
            const _TestModeChip(),
          ],
        ],
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.current});

  static const List<String> _labels = <String>['Order', 'Checkout', 'Verify'];

  final int current;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        children: [
          for (int i = 0; i < _labels.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                  color: i <= current
                      ? AppColors.brandPrimary.withOpacity(0.7)
                      : AppColors.borderDark,
                ),
              ),
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= current
                        ? AppColors.brandPrimary
                        : AppColors.surfaceElevatedDark,
                    border: Border.all(
                      color: i == current
                          ? AppColors.brandAccent
                          : Colors.transparent,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _labels[i],
                  style: AppTypography.caption(context).copyWith(
                    fontSize: 11,
                    color: i == current
                        ? AppColors.brandAccent
                        : AppColors.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TestModeChip extends StatelessWidget {
  const _TestModeChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.full),
        border: Border.all(color: AppColors.brandPrimary.withOpacity(0.5)),
      ),
      child: Text(
        'TEST MODE · no real money is charged',
        style: AppTypography.caption(context).copyWith(
          color: AppColors.brandAccent,
          fontSize: 10.5,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
