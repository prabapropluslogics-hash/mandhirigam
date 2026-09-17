import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/models/catalog_book.dart';
import '../../../design_system/components/buttons/app_button.dart';
import '../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../design_system/components/layout/app_gap.dart';
import '../../../design_system/theme/app_spacing.dart';
import '../../../design_system/theme/app_typography.dart';
import '../../../routing/app_router.dart';
import '../../../routing/app_routes.dart';
import '../../../state/app_config_controller.dart';
import '../../../state/auth_controller.dart';
import '../../../state/library_controller.dart';
import '../../../state/payment_controller.dart';

Future<bool> startPaymentFlow(BuildContext context, CatalogBook book) async {
  final AuthController auth = context.read<AuthController>();
  if (!auth.isAuthenticated) {
    final bool? signedIn = await AppRouter.pushNamed<bool>(
      context,
      AppRoutes.login,
      arguments: 'Sign in to purchase this book.',
    );
    if (signedIn != true) return false;
  }

  if (!context.mounted) return false;
  final PaymentController payment = context.read<PaymentController>();
  final LibraryController library = context.read<LibraryController>();
  final String appName =
      context.read<AppConfigController>().config.branding.appName;

  final result = await payment.purchase(
    bookId: book.id,
    bookTitle: book.title,
    appName: appName.isEmpty ? 'Mantirigam' : appName,
    user: auth.user,
  );

  if (!context.mounted) return false;

  if (payment.phase == PaymentPhase.success || result?.entitled == true) {
    await library.refresh();
    if (!context.mounted) return true;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Purchase complete'),
          content: Text('${book.title} is now in your library.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Read now'),
            ),
          ],
        );
      },
    );
    payment.reset();
    return true;
  }

  await showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext context) {
      return Padding(
        padding: AppInsets.page,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              payment.phase == PaymentPhase.pending
                  ? 'Payment pending'
                  : payment.phase == PaymentPhase.cancelled
                      ? 'Payment cancelled'
                      : 'Payment not complete',
              style: AppTypography.pageTitle(context),
            ),
            const AppGap.md(),
            Text(
              payment.message ??
                  'The book is not unlocked until the payment is verified.',
              style: AppTypography.helper(context),
            ),
            const AppGap.xl(),
            if (payment.phase == PaymentPhase.pending)
              AppButton(
                label: 'Check payment status',
                onPressed: () async {
                  await payment.refreshStatus();
                  if (payment.phase == PaymentPhase.success) {
                    await library.refresh();
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
              )
            else
              AppButton(
                label: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            const AppGap.sm(),
            AppOutlinedButton(
              label: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const AppGap.lg(),
          ],
        ),
      );
    },
  );
  if (payment.phase != PaymentPhase.success) {
    payment.reset();
    return false;
  }
  return true;
}
