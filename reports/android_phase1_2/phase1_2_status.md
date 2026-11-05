# Phase 1.2 Status — Android Physical Device Transparency

**Status as of local prep:** **BLOCKED — no physical Android device detected**

This file will be updated when USB debugging succeeds and screenshots are captured.

## A. Project verification (confirmed)

| Item | Value |
| ---- | ----- |
| Project path | `C:\Users\Extreme26\Documents\Mandhrigam\mandhirigam` |
| Git branch | `main` |
| Git commit | `16827a1ecab21a06688a37054c6a17dd43093094` |
| Flutter | 3.19.3 (stable) |
| Dart | 3.3.1 |
| Laptop OS | Microsoft Windows 10.0.26300 |
| Android minSdk | 23 |
| Android targetSdk | `flutter.targetSdkVersion` (from Flutter Gradle plugin) |
| Production PDF package | **`pdfrx: 1.0.84`** (pubspec.yaml + pubspec.lock) |
| Production reader | `lib/features/reader/presentation/widgets/original_pdf_reader.dart` |
| Parchment widget | `ReaderSurface` in `lib/features/reader/presentation/widgets/reader_paper.dart` |

### Discrepancy resolution

Previous reports conflicted on whether production contained `pdfrx`.

**This repository’s current `main` (`16827a1…`) does contain `pdfrx: 1.0.84`**, locked in `pubspec.lock`, and `OriginalPdfReader` imports `package:pdfrx/pdfrx.dart`.

Isolated PoC macOS harness is **not** treated as production proof. Android verification must use this project’s pdfrx dependency on a physical device.

### Important production renderer note

`pdfrx` 1.0.84 `PdfViewer` **hardcodes** `backgroundColor: Colors.white` when rasterizing pages (`pdf_viewer.dart` `_cachePageImage` / `_createPartialImage`). Soft-mask alpha therefore composites onto white inside the page bitmap, not onto Flutter widgets.

Phase 1.2 debug screen therefore uses the same package’s lower-level API:

`PdfPage.render(backgroundColor: Colors.transparent)`

— matching the Phase 1.1 host harness method that proved soft-mask survival on macOS PDFium. This still loads Android native PDFium from pdfrx 1.0.84.

## B. Input verification (confirmed)

| Check | Result |
| ----- | ------ |
| `original.pdf` SHA-256 | `d9d6ebfaea32e221e9a4465980e4cd7feaee8a45dd186d3e8001eb1199d95231` **MATCH** |
| Transparent PDF path | `phase1_1-five-pages-transparent.pdf` (also copied to `assets/debug/`) |
| Transparent PDF size | 6,936,383 bytes |
| Page count (`/Count`) | **5** |
| Soft-mask markers (`/SMask`) | **5** (one per page) |
| Page order (by Phase 1.1 report) | 1 → 7 → 25 → 33 → 13 |

## C. Android rendering (PENDING)

| Check | Result |
| ----- | ------ |
| `adb devices -l` | empty — no device |
| `flutter devices` | Windows / Chrome / Edge only |
| Emulators | none available |
| Native PDFium on Android | **not yet executed** |
| Soft-mask on Android | **not yet verified** |
| Parchment compositing on device | **not yet verified** |

## D–F. Quality / interaction / screenshots

Not captured — physical device required.

## G. Final decision (current)

**NO-GO** — Android physical-device rendering has not been performed.

macOS host PDFium PASS (`pdfrx_1_0_84_compat.json`) is **not** counted as Android PASS.

## Ready harness (waiting for USB device)

```bash
flutter run -d <DEVICE_ID> -t lib/debug/phase12_transparency_main.dart
```

Temporary files listed in `TEMP_FILES_TO_REVERT.md`.
