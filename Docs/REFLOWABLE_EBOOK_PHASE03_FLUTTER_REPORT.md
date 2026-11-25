# Phase 03 — Flutter Reflowable Rich Text V2 Implementation Report

**Date:** 2026-11-25  
**Flutter SDK:** FVM 3.19.3  
**Status:** Demo + automated verification complete — **not READY for client publish**

## Verdict

Phase 03 exercises the **existing production** Rich Text V2 parser/renderer (`RichTextDocumentView`, `ReaderInlineImage`, `ReaderSurface` / Olaichuvadi) against the Admin handoff fixture. No parallel production renderer was added. Fixtures stay out of the release asset bundle. OCR Tamil is **unreviewed** and is surfaced with an explicit verification banner. Rich Text V1 / Original PDF / Transparent PNG readers were not modified. Publishing flag `ALLOW_RICH_TEXT_V2_PUBLISH` was **not** changed.

## Inputs used

| Source | Local path |
|--------|------------|
| Admin `chapter_response.json` | `test/fixtures/reflowable-ebook/chapter_response.json` |
| Admin `yantra_page07.png` | `test/fixtures/reflowable-ebook/yantra_page07.png` |
| Yantra SHA-256 | `bb0a41aa823deb5f197e2f831fcdb29af70377521a37b921a6b9fb10b57687bd` |
| Yantra geometry | 1271×848, `fit: contain`, aspect ≈ 1.4988 |

Fixture README: `test/fixtures/reflowable-ebook/README.md` (not listed in `pubspec.yaml` assets).

## What was implemented

| Area | Location |
|------|----------|
| Fixture loader + absolute media URL rewrite for production validator | `lib/debug/reflowable_ebook/fixture_loader.dart` |
| Local `MemoryImage` provider for fixture media IDs | same (via `debugReaderImageProvider`) |
| OCR / source-verification banner (no silent text fixes) | `lib/debug/reflowable_ebook/ocr_review_banner.dart` |
| Demo screen using production `RichTextDocumentView` + `ReaderSurface` | `lib/debug/reflowable_ebook/phase03_demo_screen.dart` |
| Debug entrypoint | `lib/debug/reflowable_ebook/phase03_demo_main.dart` |
| Account-scoped rich-text scroll progress store (wired in app container / reader) | `lib/features/reader/data/rich_text_progress_store.dart` |
| Widget + unit tests + font-size screenshots | `test/reflowable_ebook_phase03_test.dart` |

### Demo run command

```bash
flutter run -d <DEVICE_ID> -t lib/debug/reflowable_ebook/phase03_demo_main.dart
```

## Mandatory demonstration checklist

| Requirement | Result |
|-------------|--------|
| 1. Render actual Tamil via native Flutter text widgets | **Pass** (widget test finds fixture Tamil / instruction label) |
| 2. Preserve Olaichuvadi `ReaderSurface` | **Pass** |
| 3. Render original Yantra independently (image block, not OCR cells) | **Pass** (1271×848 fixture PNG) |
| 4. Font sizes 16 / 22 / 28 | **Pass** |
| 5. Text reflows; Yantra aspect unchanged across sizes | **Pass** |
| 6. Line spacing, theme switch, reading-position restore | **Pass** (widget tests) |
| 7. Independent diagram zoom (`ReaderImageViewer` + `InteractiveViewer`) | **Pass** |
| 8. Comparison screenshots at font sizes | **Pass** → `docs/phase03-screenshots/` |
| 9. Protected network image loading separately from local fixture | **Pass** (Bearer `ChapterMediaLoader` unit test) |
| 10. Additional multi-section fixtures | **Not required** — sample already has heading + image + multiple paragraphs |

## Test results

```
flutter test test/reflowable_ebook_phase03_test.dart
→ 9 passed, 0 failed
```

| Test | Result |
|------|--------|
| fixture checksum and production parser keep the Yantra image block | Pass |
| relative media URLs are rejected by production parser until rewritten | Pass |
| rich text progress keys are account-scoped | Pass |
| production renderer shows Tamil, instruction label, and OCR banner | Pass |
| font sizes 16/22/28 reflow text while Yantra aspect stays fixed | Pass |
| theme and line-height switching keep Yantra geometry | Pass |
| reading position can be restored after scroll | Pass |
| diagram opens independent zoom viewer | Pass |
| protected network media path uses Bearer media loader separately | Pass |

```
flutter analyze lib/debug/reflowable_ebook test/reflowable_ebook_phase03_test.dart
→ No issues found
```

## Screenshots

Captured from the production renderer path under test (viewport 420×1100):

- `docs/phase03-screenshots/font_16_olaichuvadi.png`
- `docs/phase03-screenshots/font_22_olaichuvadi.png`
- `docs/phase03-screenshots/font_28_olaichuvadi.png`

Each shows the OCR verification banner, demo controls, Olaichuvadi paper surface, reflowable Tamil body, and the framed 9×9 Yantra with fixed aspect.

## Device verification status

| Target | Status |
|--------|--------|
| Widget-test “device” (Flutter test binding) | **Verified** — all Phase 03 cases green |
| Physical iPhone (“Proplus Iphone”) | **Not connected** — wireless/LAN discovery failed (unlocked + Developer Mode required) |
| Android emulator / device | **Not available** in this session |
| macOS desktop `flutter build/run` of debug entrypoint | **Blocked** — CocoaPods / `google_sign_in_ios` minimum deployment target; host disk near full during attempt |

**Physical / interactive device confirmation remains open** before any client-facing demo.

## Unreviewed OCR — do not treat as publishable

Fixture `reviewNotes.humanVerificationRequired: true`. Banner text requires source-PDF verification. Example unreviewed title OCR left **unchanged** in the fixture (e.g. strings matching Admin sample such as imperfect title OCR). **Do not silently correct** these strings for demos.

Publishing flag remains disabled per Admin notes (`ALLOW_RICH_TEXT_V2_PUBLISH`).

## Remaining blockers

1. **Human OCR verification** of Tamil against the source PDF before any client demonstration or publication.
2. **Physical device run** of `phase03_demo_main.dart` (iOS preferred) for interactive zoom / theme / reflow confirmation.
3. **Host disk space** (~0.8 GiB free after clean) — may block local release builds until cleaned further.
4. **macOS desktop demo build** needs deployment-target / CocoaPods alignment if desktop is used for demos.
5. **Rich Text V2 publish flag** intentionally unchanged — content must stay draft/preview until Admin clears OCR + flag policy.
6. Multi-page Tantrik corpus (33 pages / 65 diagrams) is **not** bundled as Flutter fixtures; only page-7 sample. More fixtures can be copied under `test/fixtures/reflowable-ebook/` when Admin provides them — still keep them out of `pubspec.yaml`.

## Explicit non-goals (honored)

- No backend / production data / feature-flag changes.
- No second production renderer for the demo.
- No OCR Tamil “cleanup” in the fixture.
- Fixtures not added to release assets.
- Rich Text V1, Original PDF, Transparent PNG readers preserved.

## Ready?

**Not READY for client publication.** Phase 03 Flutter demonstration and automated proof against the Admin sample are complete; OCR review and on-device interactive sign-off remain blockers.
