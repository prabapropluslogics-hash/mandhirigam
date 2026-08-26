import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../design_system/theme/app_theme.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';

/// Root widget for Maanthirigam.
class MaanthirigamApp extends StatelessWidget {
  const MaanthirigamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      navigatorKey: AppRouter.navigatorKey,
      initialRoute: AppRoutes.foundation,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
