import 'package:flutter/material.dart';

import '../features/book_details/presentation/screens/book_details_screen.dart';
import '../features/shell/presentation/screens/main_shell.dart';
import 'app_routes.dart';

/// Centralized route table and navigation helpers.
abstract final class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return _page(const MainShell(), settings);
      case AppRoutes.bookDetails:
        final String bookId = settings.arguments is String
            ? settings.arguments! as String
            : 'amber-sea';
        return _page(BookDetailsScreen(bookId: bookId), settings);
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
