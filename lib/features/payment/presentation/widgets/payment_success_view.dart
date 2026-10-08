import 'package:flutter/material.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/buttons/app_button_shared.dart';
import '../../../../design_system/components/buttons/app_icon_button.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../design_system/theme/brand_theme.dart';

enum PaymentSuccessAction { readNow, library, close }

/// Full-screen confirmation shown only after the backend confirmed the
/// entitlement (verified payment, or the book was already owned).
class PaymentSuccessView extends StatelessWidget {
  const PaymentSuccessView({
    super.key,
    required this.bookTitle,
    this.alreadyOwned = false,
  });

  final String bookTitle;
  final bool alreadyOwned;

  static Future<PaymentSuccessAction> show(
    BuildContext context, {
    required String bookTitle,
    bool alreadyOwned = false,
  }) async {
    // Opaque, so the screens below (and their busy indicators) pause.
    final PaymentSuccessAction? action =
        await Navigator.of(context).push<PaymentSuccessAction>(
      PageRouteBuilder<PaymentSuccessAction>(
        fullscreenDialog: true,
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (BuildContext context, _, __) => PaymentSuccessView(
          bookTitle: bookTitle,
          alreadyOwned: alreadyOwned,
        ),
        transitionsBuilder: (
          BuildContext context,
          Animation<double> animation,
          _,
          Widget child,
        ) {
          final Animation<double> curved =
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
    return action ?? PaymentSuccessAction.close;
  }

  @override
  Widget build(BuildContext context) {
    void close(PaymentSuccessAction action) =>
        Navigator.of(context).pop(action);

    return BrandTheme(
      child: Material(
        color: AppColors.splashBase,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.35),
              radius: 0.9,
              colors: <Color>[
                AppColors.brandPrimary.withOpacity(0.14),
                AppColors.splashBase.withOpacity(0),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                  child: AppIconButton(
                    icon: AppIcons.close,
                    tooltip: 'Close',
                    color: AppColors.textSecondaryDark,
                    onPressed: () => close(PaymentSuccessAction.close),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                      vertical: AppSpacing.huge,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(child: _SuccessMark()),
                          const AppGap.xxl(),
                          Semantics(
                            header: true,
                            liveRegion: true,
                            child: Text(
                              alreadyOwned
                                  ? 'Already in your library'
                                  : 'Payment Successful',
                              textAlign: TextAlign.center,
                              style: AppTypography.bookTitle(
                                context,
                                fontSize: 26,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimaryDark,
                              ),
                            ),
                          ),
                          const AppGap.md(),
                          Text(
                            '“$bookTitle”',
                            textAlign: TextAlign.center,
                            style: AppTypography.bookTitle(
                              context,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppColors.brandAccent,
                            ).copyWith(height: 1.4),
                          ),
                          const AppGap.sm(),
                          Text(
                            alreadyOwned
                                ? 'You already own this book.'
                                : 'Your purchase is confirmed.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body(context).copyWith(
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                          const AppGap.xxxl(),
                          AppButton(
                            key: const Key('payment-success-read'),
                            label: 'Read Now',
                            leadingIcon: AppIcons.read,
                            size: AppButtonSize.large,
                            backgroundColor: AppColors.brandPrimary,
                            foregroundColor: AppColors.textOnBrand,
                            onPressed: () =>
                                close(PaymentSuccessAction.readNow),
                          ),
                          const AppGap.md(),
                          AppOutlinedButton(
                            key: const Key('payment-success-library'),
                            label: 'Go to Library',
                            onPressed: () =>
                                close(PaymentSuccessAction.library),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.6, end: 1),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutBack,
        builder: (BuildContext context, double scale, Widget? child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.brandPrimary.withOpacity(0.12),
            border: Border.all(
              color: AppColors.brandPrimary.withOpacity(0.6),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPrimary.withOpacity(0.25),
                blurRadius: 36,
              ),
            ],
          ),
          child: const Icon(
            AppIcons.done,
            size: 48,
            color: AppColors.brandAccent,
          ),
        ),
      ),
    );
  }
}
