import 'package:flutter/material.dart';

import 'phase12_transparency_screen.dart';

/// Temporary Phase 2.1 Android transparency verification entrypoint.
///
/// Loads the 33-page research PDF from
/// `assets/debug/phase2-all-33-transparent.pdf`.
/// Remove that asset and its pubspec.yaml entry after QA, along with any
/// harness edits that should not ship.
///
/// Run (debug only, on your machine):
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
      title: 'Phase 2.1 PDF Transparency',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF7E5A28),
        useMaterial3: true,
      ),
      home: const Phase12TransparencyScreen(),
    );
  }
}
