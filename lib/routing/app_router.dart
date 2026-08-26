import 'package:flutter/material.dart';

import '../app/foundation_placeholder_page.dart';
import 'app_routes.dart';

/// Centralized route table and navigation helpers.
///
/// Keep all named routes here so feature modules do not register routes ad-hoc.
abstract final class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.foundation:
        return _page(const FoundationPlaceholderPage(), settings);
      default:
        return _page(
          Scaffold(
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
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
