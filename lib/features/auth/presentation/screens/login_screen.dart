import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/buttons/app_outlined_button.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/icons/app_icons.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../state/app_config_controller.dart';
import '../../../../state/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final AuthController auth = context.watch<AuthController>();
    final String appName =
        context.watch<AppConfigController>().config.branding.appName;

    return AppScaffold(
      body: Padding(
        padding: AppInsets.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(AppIcons.back),
              ),
            ),
            const Spacer(),
            Text(
              appName.isEmpty ? 'Mantirigam' : appName,
              style: AppTypography.display(context),
              textAlign: TextAlign.center,
            ),
            const AppGap.sm(),
            Text(
              'Sign in to purchase books and open your library.',
              style: AppTypography.helper(context),
              textAlign: TextAlign.center,
            ),
            if (message != null && message!.isNotEmpty) ...[
              const AppGap.lg(),
              Text(
                message!,
                style: AppTypography.helper(context),
                textAlign: TextAlign.center,
              ),
            ],
            if (auth.errorMessage != null) ...[
              const AppGap.md(),
              Text(
                auth.errorMessage!,
                style: AppTypography.error(context),
                textAlign: TextAlign.center,
              ),
            ],
            const AppGap.xxl(),
            AppButton(
              label: 'Continue with Google',
              isLoading: auth.signingIn,
              onPressed: () async {
                final bool ok = await context.read<AuthController>().signInWithGoogle();
                if (ok && context.mounted) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
            const AppGap.md(),
            AppOutlinedButton(
              label: 'Continue as guest',
              onPressed: () => Navigator.of(context).maybePop(false),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
