import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/catalog_book.dart';
import '../../../data/models/payment.dart';
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
import '../../../state/app_config_controller.dart';
import '../../../state/auth_controller.dart';
import '../../../state/library_controller.dart';
import '../../../state/payment_controller.dart';
import '../../auth/presentation/require_sign_in.dart';
import 'widgets/payment_progress_dialog.dart';

enum _NextStep { retry, verified, close }

/// Create order → Razorpay → backend verification for [book].
///
/// The user always stays on the calling screen. Returns `true` only when the
/// backend confirmed the entitlement; the library is refreshed in that case.
Future<bool> startPaymentFlow(BuildContext context, CatalogBook book) async {
  if (!await requireSignIn(context, message: 'Sign in to buy ${book.title}.')) {
    return false;
  }
  if (!context.mounted) return false;

  final AuthController auth = context.read<AuthController>();
  final PaymentController payment = context.read<PaymentController>();
  final LibraryController library = context.read<LibraryController>();
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final String appName =
      context.read<AppConfigController>().config.branding.appName;

  while (true) {
    final Route<void> progress = PaymentProgressDialog.show(
      context,
      payment: payment,
      bookTitle: book.title,
    );
    final PaymentStatusResult? result;
    try {
      result = await payment.purchase(
        bookId: book.id,
        bookTitle: book.title,
        appName: appName.isEmpty ? 'Mantirigam' : appName,
        user: auth.user,
      );
    } finally {
      PaymentProgressDialog.dismiss(progress);
    }

    if (payment.phase == PaymentPhase.success || result?.entitled == true) {
      return _completeVerified(payment, library, messenger, book);
    }
    if (payment.phase == PaymentPhase.cancelled) {
      payment.reset();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
        const SnackBar(content: Text('Payment cancelled.')),
      );
      return false;
    }
    if (payment.phase == PaymentPhase.idle || !context.mounted) {
      payment.reset();
      return false;
    }

    final _NextStep step = await showModalBottomSheet<_NextStep>(
          context: context,
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.bottomSheetBorder,
          ),
          builder: (_) => _PaymentIssueSheet(payment: payment),
        ) ??
        _NextStep.close;
    if (step == _NextStep.verified) {
      return _completeVerified(payment, library, messenger, book);
    }
    payment.reset();
    if (step != _NextStep.retry || !context.mounted) return false;
  }
}

Future<bool> _completeVerified(
  PaymentController payment,
  LibraryController library,
  ScaffoldMessengerState messenger,
  CatalogBook book,
) async {
  final String message =
      payment.message ?? 'Purchase complete. ${book.title} is unlocked.';
  payment.reset();
  await library.recordVerifiedPurchase(book.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              AppIcons.checkFilled,
              size: AppSizes.iconMd,
              color: AppColors.brandPrimary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  return true;
}

class _PaymentIssueSheet extends StatefulWidget {
  const _PaymentIssueSheet({required this.payment});

  final PaymentController payment;

  @override
  State<_PaymentIssueSheet> createState() => _PaymentIssueSheetState();
}

class _PaymentIssueSheetState extends State<_PaymentIssueSheet> {
  bool _checking = false;

  bool get _pending => widget.payment.phase == PaymentPhase.pending;

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    await widget.payment.refreshStatus();
    if (!mounted) return;
    if (widget.payment.phase == PaymentPhase.success) {
      Navigator.of(context).pop(_NextStep.verified);
      return;
    }
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final String orderId = widget.payment.lastOrder?.orderId ?? '';
    return BrandTheme(
      child: SafeArea(
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
              Center(child: _IssueIcon(pending: _pending)),
              const AppGap.lg(),
              Text(
                _pending ? 'Payment pending' : 'Payment not completed',
                textAlign: TextAlign.center,
                style: AppTypography.bookTitle(
                  context,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimaryDark,
                ),
              ),
              const AppGap.sm(),
              Text(
                widget.payment.message ??
                    'The book is not unlocked until the payment is verified.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(context).copyWith(
                  color: AppColors.textSecondaryDark,
                ),
              ),
              if (orderId.isNotEmpty) ...[
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
              if (_pending)
                AppButton(
                  label: 'Check payment status',
                  isLoading: _checking,
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: AppColors.textOnBrand,
                  onPressed: _checkStatus,
                )
              else
                AppButton(
                  label: 'Try again',
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: AppColors.textOnBrand,
                  onPressed: () => Navigator.of(context).pop(_NextStep.retry),
                ),
              const AppGap.sm(),
              AppOutlinedButton(
                label: 'Close',
                onPressed: () => Navigator.of(context).pop(_NextStep.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IssueIcon extends StatelessWidget {
  const _IssueIcon({required this.pending});

  final bool pending;

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
          pending ? AppIcons.pending : AppIcons.error,
          size: AppSizes.iconLg,
          color: AppColors.brandAccent,
        ),
      ),
    );
  }
}
