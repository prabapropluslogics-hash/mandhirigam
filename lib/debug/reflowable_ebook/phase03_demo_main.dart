import 'package:flutter/material.dart';

import 'phase03_demo_screen.dart';

/// Debug-only Phase 03 entrypoint for the reflowable Rich Text V2 fixture.
///
/// Uses the production [RichTextDocumentView] / [ReaderSurface] path with
/// local fixtures under `test/fixtures/reflowable-ebook/` (not release assets).
///
/// ```
/// flutter run -d <DEVICE_ID> -t lib/debug/reflowable_ebook/phase03_demo_main.dart
/// ```
///
/// Do not enable `ALLOW_RICH_TEXT_V2_PUBLISH` from this harness. OCR Tamil in
/// the fixture requires human verification against the source PDF.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Phase03ReflowableDemoApp());
}

class Phase03ReflowableDemoApp extends StatelessWidget {
  const Phase03ReflowableDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: true,
      title: 'Phase 03 Reflowable V2',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF7E5A28),
        useMaterial3: true,
      ),
      home: const Phase03ReflowableDemoScreen(),
    );
  }
}
