import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/catalog_book.dart';
import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../design_system/components/layout/app_gap.dart';
import '../../../design_system/icons/app_icons.dart';
import '../../../design_system/theme/app_colors.dart';
import '../../../design_system/theme/app_radii.dart';
import '../../../design_system/theme/app_sizes.dart';
import '../../../design_system/theme/app_spacing.dart';
import '../../../design_system/theme/app_typography.dart';
import '../../../design_system/theme/brand_theme.dart';
import '../../../routing/back_navigation.dart';
import '../../../state/app_config_controller.dart';
import '../../../state/auth_controller.dart';
import '../../../state/library_controller.dart';
import '../../../state/payment_controller.dart';
import '../../auth/presentation/require_sign_in.dart';
import 'widgets/payment_progress_dialog.dart';
import 'widgets/payment_success_view.dart';

enum _NextStep { retry, verified, close }

/// Create order → Razorpay → backend verification for [book].
///
/// The user stays on the calling screen. Returns `true` only when the
/// backend confirmed the entitlement (or the library already lists the
/// book); the library is refreshed in that case. When the user picks
/// "Read Now" on the success screen, [onReadNow] opens the reader.
Future<bool> startPaymentFlow(
  BuildContext context,
  CatalogBook book, {
  Future<void> Function()? onReadNow,
}) async {
  if (!await requireSignIn(context, message: 'Sign in to buy ${book.title}.')) {
    return false;
  }
  if (!context.mounted) return false;

  final AuthController auth = context.read<AuthController>();
  final PaymentController payment = context.read<PaymentController>();
  final LibraryController library = context.read<LibraryController>();
  final String appName =
      context.read<AppConfigController>().config.branding.appName;
  if (payment.busy) return false;

  if (!library.loaded) await library.refresh();
  if (!context.mounted) return false;
  if (library.owns(book.id)) return true;

  while (true) {
    final Route<void> progress = PaymentProgressDialog.show(
      context,
      payment: payment,
      bookTitle: book.title,
    );
    try {
      await payment.purchase(
        bookId: book.id,
        bookTitle: book.title,
        appName: appName.trim().isEmpty ? 'Maanthirigam' : appName,
        user: auth.user,
      );
    } finally {
      PaymentProgressDialog.dismiss(progress);
    }

    if (payment.phase == PaymentPhase.success) {
      if (!context.mounted) return true;
      return _completeVerified(context, payment, library, book, onReadNow);
    }
    if (payment.phase == PaymentPhase.idle || !context.mounted) {
      payment.reset();
      return false;
    }

    final bool wasPending = payment.phase == PaymentPhase.pending;
    final _NextStep step = await showModalBottomSheet<_NextStep>(
          context: context,
          backgroundColor: AppColors.surfaceDark,
          isScrollControlled: true,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.bottomSheetBorder,
          ),
          builder: (_) => _PaymentIssueSheet(payment: payment),
        ) ??
        _NextStep.close;
    if (step == _NextStep.verified && context.mounted) {
      return _completeVerified(context, payment, library, book, onReadNow);
    }
    final bool verifyLater = wasPending || payment.paymentSubmitted;
    payment.reset();
    // The backend (webhook or a later check) may still confirm it; the
    // library is the source of truth for ownership.
    if (verifyLater) unawaited(library.refresh());
    if (step != _NextStep.retry || !context.mounted) return false;
  }
}

Future<bool> _completeVerified(
  BuildContext context,
  PaymentController payment,
  LibraryController library,
  CatalogBook book,
  Future<void> Function()? onReadNow,
) async {
  final bool alreadyOwned = payment.alreadyOwned;
  payment.reset();
  await library.recordVerifiedPurchase(book.id);
  if (!context.mounted) return true;
  final PaymentSuccessAction action = await PaymentSuccessView.show(
    context,
    bookTitle: book.title,
    alreadyOwned: alreadyOwned,
  );
  if (!context.mounted) return true;
  switch (action) {
    case PaymentSuccessAction.readNow:
      if (onReadNow != null) await onReadNow();
    case PaymentSuccessAction.library:
      BackNavigation.goToLibrary(context);
    case PaymentSuccessAction.close:
      break;
  }
  return true;
}

/// Cancelled, failed or still-verifying purchase. Offers "Try Again" only
/// when no payment was made for the order, and "Check Payment Status" when
/// the backend may still confirm it.
class _PaymentIssueSheet extends StatelessWidget {
  const _PaymentIssueSheet({required this.payment});

  final PaymentController payment;

  Future<void> _checkStatus(BuildContext context) async {
    await payment.refreshStatus();
    if (!context.mounted) return;
    if (payment.phase == PaymentPhase.success) {
      Navigator.of(context).pop(_NextStep.verified);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BrandTheme(
      child: AnimatedBuilder(
        animation: payment,
        builder: (BuildContext context, _) => _content(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final PaymentPhase phase = payment.phase;
    final bool submitted = payment.paymentSubmitted;
    final (String title, String fallback, IconData icon) = switch (phase) {
      PaymentPhase.cancelled => (
          'Payment cancelled',
          PaymentController.cancelledMessage,
          AppIcons.cancelled,
        ),
      PaymentPhase.pending => (
          'Payment is being verified',
          PaymentController.verifyingMessage,
          AppIcons.pending,
        ),
      _ when submitted => (
          'Payment not confirmed',
          'We could not confirm this payment. The book is not unlocked.',
          AppIcons.error,
        ),
      _ => (
          'Payment unsuccessful',
          PaymentController.failedMessage,
          AppIcons.error,
        ),
    };
    final String orderId = payment.lastOrder?.orderId ?? '';
    final bool showReference =
        orderId.isNotEmpty && (submitted || phase == PaymentPhase.pending);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _IssueIcon(icon: icon)),
            const AppGap.lg(),
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTypography.bookTitle(
                  context,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ),
            const AppGap.sm(),
            Text(
              payment.message ?? fallback,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(context).copyWith(
                color: AppColors.textSecondaryDark,
              ),
            ),
            if (showReference) ...[
              const AppGap.sm(),
              SelectableText(
                'Reference: $orderId',
                textAlign: TextAlign.center,
                style: AppTypography.caption(context).copyWith(
                  color: AppColors.neutral400,
                ),
              ),
            ],
            const AppGap.xl(),
            if (payment.canCheckStatus)
              AppButton(
                label: 'Check Payment Status',
                isLoading: payment.checkingStatus,
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: AppColors.textOnBrand,
                onPressed: () => _checkStatus(context),
              )
            else if (payment.canRetryPurchase)
              AppButton(
                label: 'Try Again',
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: AppColors.textOnBrand,
                onPressed: () => Navigator.of(context).pop(_NextStep.retry),
              ),
            const AppGap.sm(),
            AppOutlinedButton(
              label: 'Close',
              onPressed: payment.checkingStatus
                  ? null
                  : () => Navigator.of(context).pop(_NextStep.close),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueIcon extends StatelessWidget {
  const _IssueIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brandPrimary.withOpacity(0.1),
          border: Border.all(color: AppColors.brandPrimary.withOpacity(0.45)),
        ),
        child: Icon(
          icon,
          size: AppSizes.iconLg,
          color: AppColors.brandAccent,
        ),
      ),
    );
  }
}
