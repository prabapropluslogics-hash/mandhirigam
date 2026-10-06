import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_routes.dart';

/// App-wide Android back rule: from any inner screen one system back returns
/// to Home; Home itself asks for a second back before exiting (see MainShell).
///
/// Only the system back (button, gesture, predictive back) is affected.
/// On-screen back buttons call `Navigator.pop` and keep their own behaviour.
abstract final class BackNavigation {
  /// Incremented whenever the shell should show its Home tab.
  static final ValueNotifier<int> homeTabRequests = ValueNotifier<int>(0);

  /// Pops every route above Home and selects the Home tab. Popped routes
  /// complete with `null`, so awaiting callers (e.g. sign-in) get a result.
  static void goHome(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context);
    bool foundHome = false;
    navigator.popUntil((Route<dynamic> route) {
      if (route.settings.name == AppRoutes.home) {
        foundHome = true;
        return true;
      }
      return route.isFirst;
    });
    if (!foundHome) {
      navigator.pushReplacementNamed(AppRoutes.home);
    }
    homeTabRequests.value++;
  }
}

/// Wraps an inner route so the Android system back goes straight to Home.
/// iOS keeps its normal swipe-back.
class ReturnHomeOnBack extends StatelessWidget {
  const ReturnHomeOnBack({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return child;
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) BackNavigation.goHome(context);
      },
      child: child,
    );
  }
}
