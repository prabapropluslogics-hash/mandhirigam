import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/open_url.dart';
import '../../../../core/utils/version_compare.dart';
import '../../../../data/models/app_config.dart';
import '../../../../design_system/components/buttons/app_button.dart';
import '../../../../design_system/components/feedback/app_loader.dart';
import '../../../../design_system/components/layout/app_gap.dart';
import '../../../../design_system/components/layout/app_scaffold.dart';
import '../../../../design_system/theme/app_spacing.dart';
import '../../../../design_system/theme/app_typography.dart';
import '../../../../routing/app_router.dart';
import '../../../../routing/app_routes.dart';
import '../../../../state/app_config_controller.dart';
import '../../../../state/auth_controller.dart';
import '../../../../state/catalog_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_starting) return;
    _starting = true;
    final AuthController auth = context.read<AuthController>();
    final AppConfigController config = context.read<AppConfigController>();
    await auth.restore();
    await config.load();
    if (!mounted) return;
    if (config.errorMessage != null) {
      setState(() => _starting = false);
      return;
    }
    if (config.updateKind == AppUpdateKind.required) {
      setState(() => _starting = false);
      return;
    }
    if (config.updateKind == AppUpdateKind.optional) {
      await _showOptionalUpdate(config);
      if (!mounted) return;
    }
    unawaited(context.read<CatalogController>().load());
    AppRouter.navigatorKey.currentState?.pushReplacementNamed(AppRoutes.home);
  }

  Future<void> _showOptionalUpdate(AppConfigController config) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update available'),
          content: Text(
            config.config.appUpdate.updateMessage.isEmpty
                ? 'A newer version of the app is available.'
                : config.config.appUpdate.updateMessage,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Later'),
            ),
            TextButton(
              onPressed: () {
                openSafeHttpUrl(config.platformUpdate.storeUrl);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppConfigController config = context.watch<AppConfigController>();
    final BrandingConfig branding = config.config.branding;

    if (config.loaded && config.updateKind == AppUpdateKind.required) {
      return _ForceUpdateView(config: config);
    }

    return AppScaffold(
      body: Padding(
        padding: AppInsets.page,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              branding.appName.isEmpty ? 'Mantirigam' : branding.appName,
              style: AppTypography.display(context),
              textAlign: TextAlign.center,
            ),
            if (branding.tagline.isNotEmpty) ...[
              const AppGap.sm(),
              Text(
                branding.tagline,
                style: AppTypography.helper(context),
                textAlign: TextAlign.center,
              ),
            ],
            const AppGap.xxl(),
            if (config.errorMessage != null) ...[
              Text(
                config.errorMessage!,
                style: AppTypography.helper(context),
                textAlign: TextAlign.center,
              ),
              const AppGap.lg(),
              AppButton(
                label: 'Retry',
                isExpanded: false,
                onPressed: () {
                  setState(() => _starting = false);
                  _bootstrap();
                },
              ),
            ] else
              const AppLoader(),
          ],
        ),
      ),
    );
  }
}

class _ForceUpdateView extends StatelessWidget {
  const _ForceUpdateView({required this.config});

  final AppConfigController config;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Padding(
        padding: AppInsets.page,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Update required', style: AppTypography.pageTitle(context)),
            const AppGap.md(),
            Text(
              config.config.appUpdate.updateMessage.isEmpty
                  ? 'Please update the app to continue.'
                  : config.config.appUpdate.updateMessage,
              style: AppTypography.helper(context),
              textAlign: TextAlign.center,
            ),
            const AppGap.xxl(),
            AppButton(
              label: 'Update now',
              onPressed: () => openSafeHttpUrl(config.platformUpdate.storeUrl),
            ),
          ],
        ),
      ),
    );
  }
}
