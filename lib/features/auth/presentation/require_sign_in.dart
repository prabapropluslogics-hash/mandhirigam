import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../routing/app_router.dart';
import '../../../routing/app_routes.dart';
import '../../../state/auth_controller.dart';

/// Opens the login screen on top of the current screen when needed and
/// resolves once the user is back on it. `true` means signed in.
Future<bool> requireSignIn(BuildContext context, {required String message}) async {
  if (context.read<AuthController>().isAuthenticated) return true;
  // Routes are built as MaterialPageRoute<dynamic>, so a typed push would
  // fail its cast; the login screen pops with a bool.
  final Object? signedIn = await AppRouter.pushNamed<Object?>(
    context,
    AppRoutes.login,
    arguments: message,
  );
  if (signedIn != true || !context.mounted) return false;
  return context.read<AuthController>().isAuthenticated;
}
