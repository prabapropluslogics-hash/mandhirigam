import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_container.dart';
import '../core/constants/app_constants.dart';
import '../design_system/theme/app_colors.dart';
import '../design_system/theme/app_theme.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';
import '../state/app_config_controller.dart';
import '../state/auth_controller.dart';
import '../state/library_controller.dart';

class MaanthirigamApp extends StatefulWidget {
  const MaanthirigamApp({super.key, required this.container});

  final AppContainer container;

  @override
  State<MaanthirigamApp> createState() => _MaanthirigamAppState();
}

class _MaanthirigamAppState extends State<MaanthirigamApp> {
  @override
  void initState() {
    super.initState();
    widget.container.authController.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.container.authController.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    final AuthController auth = widget.container.authController;
    if (!auth.sessionExpired) return;
    auth.consumeSessionExpired();
    widget.container.libraryController.clearLocal();
    final NavigatorState? nav = AppRouter.navigatorKey.currentState;
    if (nav == null) return;
    nav.pushNamedAndRemoveUntil(AppRoutes.home, (Route<dynamic> route) => false);
    nav.pushNamed(
      AppRoutes.login,
      arguments: 'Please sign in again to continue.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppContainer>.value(value: widget.container),
        ChangeNotifierProvider<AuthController>.value(
          value: widget.container.authController,
        ),
        ChangeNotifierProvider<AppConfigController>.value(
          value: widget.container.appConfigController,
        ),
        ChangeNotifierProvider.value(value: widget.container.catalogController),
        ChangeNotifierProvider<LibraryController>.value(
          value: widget.container.libraryController,
        ),
        ChangeNotifierProvider.value(value: widget.container.paymentController),
      ],
      child: Consumer<AppConfigController>(
        builder: (BuildContext context, AppConfigController config, _) {
          final BrandingColors branding = BrandingColors.fromConfig(
            config.config.branding,
          );
          final String title = config.config.branding.appName.isEmpty
              ? AppConstants.appName
              : config.config.branding.appName;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: AppColors.backgroundDark,
              systemNavigationBarIconBrightness: Brightness.light,
            ),
            child: MaterialApp(
              title: title,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(branding: branding),
              darkTheme: AppTheme.dark(branding: branding),
              themeMode: ThemeMode.dark,
              navigatorKey: AppRouter.navigatorKey,
              initialRoute: AppRoutes.splash,
              onGenerateRoute: AppRouter.onGenerateRoute,
            ),
          );
        },
      ),
    );
  }
}
