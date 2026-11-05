# Phase 1.2 temporary files — revert after Android QA

Do **not** commit these without explicit approval.

## Added (temporary)

- `lib/debug/phase12_transparency_main.dart`
- `lib/debug/phase12_transparency_screen.dart`
- `assets/debug/phase1_1-five-pages-transparent.pdf` (copy of root supplied PDF)
- `reports/android_phase1_2/` (this folder — keep screenshots/report)

## Modified (temporary)

- `pubspec.yaml` — added asset entry:
  `assets/debug/phase1_1-five-pages-transparent.pdf`

## Unchanged (do not touch)

- Production reader (`original_pdf_reader.dart`, routing, APIs)
- Supplied root artifacts: `original.pdf`, `phase1_1-five-pages-transparent.pdf`,
  `phase1_1_report.md`, `pdfrx_1_0_84_compat.json`

## Run command

```bash
flutter run -d <DEVICE_ID> -t lib/debug/phase12_transparency_main.dart
```
