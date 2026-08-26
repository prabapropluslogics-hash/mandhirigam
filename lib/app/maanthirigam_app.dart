import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_constants.dart';
import '../design_system/theme/app_colors.dart';
import '../design_system/theme/app_theme.dart';
import '../routing/app_router.dart';
import '../routing/app_routes.dart';

/// Root widget for Maanthirigam.
class MaanthirigamApp extends StatelessWidget {
  const MaanthirigamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.backgroundDark,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.dark,
        navigatorKey: AppRouter.navigatorKey,
        initialRoute: AppRoutes.home,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
