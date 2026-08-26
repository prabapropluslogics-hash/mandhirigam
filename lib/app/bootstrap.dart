import 'package:flutter/widgets.dart';

import 'maanthirigam_app.dart';

/// Application entry bootstrap.
///
/// Keep startup side-effects here later (orientation, local storage init, etc.)
/// without mixing them into UI widgets.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaanthirigamApp());
}
