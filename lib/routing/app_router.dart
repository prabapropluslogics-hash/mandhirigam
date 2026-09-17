import 'package:flutter/material.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/book_details/presentation/screens/book_details_screen.dart';
import '../features/reader/presentation/screens/reader_screen.dart';
import '../features/shell/presentation/screens/main_shell.dart';
import '../features/startup/presentation/screens/splash_screen.dart';
import 'app_routes.dart';

/// Centralized route table and navigation helpers.
abstract final class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _page(const SplashScreen(), settings);
      case AppRoutes.home:
        return _page(const MainShell(), settings);
      case AppRoutes.login:
        return _page(
          LoginScreen(
            message: settings.arguments is String
                ? settings.arguments! as String
                : null,
          ),
          settings,
        );
      case AppRoutes.bookDetails:
        final String bookId = settings.arguments is String
            ? settings.arguments! as String
            : '';
        return _page(BookDetailsScreen(bookId: bookId), settings);
      case AppRoutes.reader:
        final Object? args = settings.arguments;
        if (args is ReaderArgs) {
          return _page(ReaderScreen(args: args), settings);
        }
        return _page(
          const Scaffold(body: Center(child: Text('Reader unavailable'))),
          settings,
        );
      default:
        return _page(
          const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
          settings,
        );
    }
  }

  static MaterialPageRoute<T> _page<T>(Widget child, RouteSettings settings) {
    return MaterialPageRoute<T>(
      builder: (_) => child,
      settings: settings,
    );
  }

  static Future<T?> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
  }

  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context).pop<T>(result);
  }
}
