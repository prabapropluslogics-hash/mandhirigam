import 'package:flutter/material.dart';

import 'phase12_transparency_screen.dart';

/// Temporary Phase 2.3 PNG transparency verification entrypoint.
///
/// Shows the 33 packed page PNGs from `assets/debug/phase2_png/`.
/// PDFium is not used. Remove that asset directory, its pubspec.yaml entry,
/// and this harness after QA.
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
      title: 'Phase 2.3 PNG pages',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF7E5A28),
        useMaterial3: true,
      ),
      home: const Phase12TransparencyScreen(),
    );
  }
}
