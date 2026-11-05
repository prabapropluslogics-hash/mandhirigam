import 'package:flutter/material.dart';

import 'phase12_transparency_screen.dart';

/// Temporary Phase 1.2 Android transparency verification entrypoint.
///
/// Run (debug only):
/// ```
/// flutter run -d <DEVICE_ID> -t lib/debug/phase12_transparency_main.dart
/// ```
///
/// Does not touch production bootstrap, auth, payments, or reader routing.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Phase12TransparencyApp());
}

class Phase12TransparencyApp extends StatelessWidget {
  const Phase12TransparencyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      title: 'Phase 1.2 PDF Transparency',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF7E5A28),
        useMaterial3: true,
      ),
      home: const Phase12TransparencyScreen(),
    );
  }
}
