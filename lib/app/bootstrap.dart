import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import '../core/app_container.dart';
import 'maanthirigam_app.dart';

Future<void> bootstrap({AppContainer? container}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebase();
  runApp(MaanthirigamApp(container: container ?? AppContainer.create()));
}

/// Uses the native config (google-services.json / GoogleService-Info.plist).
/// A failure keeps the app usable as a guest; sign-in reports the problem.
Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (error) {
    debugPrint('Firebase initialization failed: $error');
  }
}
