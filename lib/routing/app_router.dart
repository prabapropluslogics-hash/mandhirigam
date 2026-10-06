import 'package:flutter/material.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/book_details/presentation/screens/book_details_screen.dart';
import '../features/reader/presentation/screens/reader_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/shell/presentation/screens/main_shell.dart';
import '../features/startup/presentation/screens/splash_screen.dart';
import 'app_routes.dart';
import 'back_navigation.dart';

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
        final Object? args = settings.arguments;
        if (args is BookDetailsArgs) {
          return _page(
            BookDetailsScreen(bookId: args.bookId, preview: args.preview),
            settings,
          );
        }
        final String bookId = args is String ? args : '';
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
      case AppRoutes.settings:
        return _page(const SettingsScreen(), settings);
      default:
        return _page(
          const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
          settings,
        );
    }
  }

  /// Routes whose system back is not redirected to Home: startup, Home itself
  /// (double-back exit lives in MainShell) and login, which must hand its
  /// true/false result back to `requireSignIn` callers.
  static const Set<String> _ownBackRoutes = <String>{
    AppRoutes.splash,
    AppRoutes.home,
    AppRoutes.login,
  };

  static MaterialPageRoute<T> _page<T>(Widget child, RouteSettings settings) {
    final Widget page = _ownBackRoutes.contains(settings.name)
        ? child
        : ReturnHomeOnBack(child: child);
    return MaterialPageRoute<T>(
      builder: (_) => page,
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

/// Tracks the name of the top-most route of the root navigator.
class CurrentRouteObserver extends NavigatorObserver {
  final List<Route<dynamic>> _stack = <Route<dynamic>>[];

  String? get currentName => _stack.isEmpty ? null : _stack.last.settings.name;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final int index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (newRoute == null) return;
    if (index >= 0) {
      _stack[index] = newRoute;
    } else {
      _stack.add(newRoute);
    }
  }
}
