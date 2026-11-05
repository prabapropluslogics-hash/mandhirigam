# Phase 1.1 Final Report — Dense Yantra Protection, Fringe Cleanup, pdfrx Verification

## Scope

Isolated research under `tools/pdf-transparency-poc/` only. No Admin, Backend, or production Flutter changes. Original PDF untouched.

| Field | Value |
| ----- | ----- |
| Input | `input/original.pdf` |
| SHA-256 | `d9d6ebfaea32e221e9a4465980e4cd7feaee8a45dd186d3e8001eb1199d95231` (unchanged) |
| Pages processed | 1, 7, 25, 33, 13 (not all 33) |
| Output root | `output/phase1_1/` (Phase 1 outputs retained separately) |
| Script | `scripts/03_phase1_1_process.py` |
| pdfrx harness | `pdfrx_compat/` pinned to **pdfrx 1.0.84** |

## What changed vs Phase 1

### A. Dense Yantra protection

**Root cause of page-7 leakage:** the 9×9 Yantra is an **embedded raster image** (`xref 103`, 1379×909) with white cell interiors. Contour-hierarchy alone could not reliably seal every cell when grid strokes were anti-aliased.

**Phase 1.1 strategy (priority order):**

1. **Embedded PDF image placement rects** → solid opaque protect of the full diagram bbox (primary fix for page 7).
2. Red/dark morphological H/V lines + Hough **on line candidates only** (not full-page Canny — that previously merged text into page-sized false grids).
3. Projection-profile row/col reconstruction inside candidate ROIs.
4. Contour-hierarchy cell fill as backup for smaller grids.
5. If uncertain but ROI is modest → solid opaque rectangle (prefer opaque white over a damaged Yantra).

**Page 7 result:** Yantra ROI protect = **100%**, `yantra_alpha0_leak = 0.0%`. White cell interiors remain opaque.

### B. Fringe cleanup

Conservative near-paper background growth excluding FG cores and Yantra protect; mild un-mix **only outside** protected Yantra regions.

Honest limit: anti-aliased ink/paper blends from the source still leave a faint chalk fringe at **400%** zoom on some strokes. Edge RGB may change on unprotected fringe pixels when un-mix runs — original edge RGB is **not** claimed preserved there. Protected Yantra / strong ink RGB is preserved (`yantra_mae = 0`).

### C. Reconstruction fidelity

Paper-background reconstruction vs original render:

| Page | Transparent % (P1 → P1.1) | SSIM | MAE | RMSE | Protected MAE | Yantra MAE | Text MAE | Fringe score |
| ---- | ------------------------- | ---- | --- | ---- | ------------- | ---------- | -------- | ------------ |
| 1 | 75.7 → **72.5** | 0.99936 | 0.073 | 0.815 | 0.213 | 0.0 | 0.0 | 1.40 |
| 7 | 61.9 → **57.7** | 0.99939 | 0.053 | 0.722 | 0.074 | 0.0 | 0.0 | 0.80 |
| 25 | 70.3 → **64.6** | 0.99937 | 0.046 | 0.679 | 0.070 | 0.0 | 0.0 | 0.68 |
| 33 | 74.0 → **69.6** | 0.99944 | 0.078 | 0.811 | 0.230 | 0.0 | 0.0 | 1.68 |
| 13 | 71.1 → **66.0** | 0.99938 | 0.058 | 0.736 | 0.122 | 0.0 | 0.0 | 1.04 |

Slightly **less** transparency than Phase 1 is expected and preferred: more Yantra/diagram area is solid-protected. Global SSIM remains ≥ 0.9993; Yantra-region error is zero.

### D. PDF soft-mask (PyMuPDF re-render)

Five-page PDF `output/phase1_1/transparent-pdf/phase1_1-five-pages-transparent.pdf` (~6.9 MB) re-renders with an alpha channel on every page; parchment composites show background through cleared regions.

### E. pdfrx 1.0.84 compatibility (mandatory)

Isolated harness: `tools/pdf-transparency-poc/pdfrx_compat/` (does **not** modify production Flutter).

| Check | Result |
| ----- | ------ |
| Opens transparent PDF | PASS |
| Opens opaque control | PASS |
| Soft-mask composites over magenta / parchment via `PdfPage.render(backgroundColor:…)` | **PASS** (host macOS PDFium) |
| Opaque control does **not** show magenta through page | PASS (0% near-magenta) |
| Continuous 5-page render with surviving ink | PASS |
| Transparent % over magenta ≈ PNG transparency | ~57–72% vs control 0% |
| Android device compositing | **PENDING** (no Android device/emulator in this environment) |

Report: `reports/pdfrx_1_0_84_compat.json` — verdict `PASS_HOST_PDFIUM`.

PNG transparency alone was **not** treated as proof; the harness compared transparent vs opaque PDFs under the same pdfrx render path.

## Acceptance criteria (per page)

| Criterion | P1 | P7 | P25 | P33 | P13 |
| --------- | -- | -- | --- | --- | --- |
| Tamil glyphs / marks preserved (page + 400% review) | PASS | PASS | PASS | PASS | PASS |
| Dense / enclosed Yantra cells opaque | PASS | **PASS** (was PARTIAL) | PASS | PASS | PASS |
| No meaningful content missing | PASS | PASS | PASS | PASS | PASS |
| No unacceptable fringe at normal zoom | PASS | PASS | PASS | PASS | PASS |
| Residual fringe at 400% | PARTIAL | PARTIAL | PARTIAL | PARTIAL | PARTIAL |
| Genuine alpha | PASS | PASS | PASS | PASS | PASS |
| Original recoverable (recon) | PASS | PASS | PASS | PASS | PASS |
| Geometry unchanged | PASS | PASS | PASS | PASS | PASS |
| Soft-mask re-render | PASS | PASS | PASS | PASS | PASS |
| Status gate | PASS_CANDIDATE | PASS_CANDIDATE | PASS_CANDIDATE | PASS_CANDIDATE | PASS_CANDIDATE |

No page was marked FAILED. Residual 400% fringe is recorded as PARTIAL, not hidden by relaxing thresholds.

## Performance / resources

| Item | Phase 1.1 |
| ---- | --------- |
| Per-page time @ 300 DPI | ~20–21 s |
| Peak approach | same Python stack (OpenCV + PyMuPDF) |
| `output/phase1_1/` size | ~102 MB (includes diagnostics/zooms) |
| Transparent 5-page PDF | ~6.9 MB |
| Original PDF | 5.1 MB, checksum unchanged |

## GO / NO-GO

### CONDITIONAL GO — continue research / limited QA

**GO enough to proceed** because:

1. Page-7 dense 9×9 Yantra white-cell leakage is fixed (solid embedded-image protect, 0% alpha leak).
2. Pages 1/25/33/13 did not regress; reconstruction SSIM improved slightly.
3. Genuine soft-mask transparency remains in PNG and PDF.
4. **pdfrx 1.0.84** host PDFium verification **PASS** (soft-mask composites over colored backgrounds; opaque control does not).

### NO-GO — full 33-page production integration

Still blocked until:

1. **Android** pdfrx compositing over the real parchment Flutter backdrop is verified on device/emulator (`android_device_verification: PENDING`).
2. Manual QA signs off residual 400% fringe as acceptable for reader UX (or a further fringe pass is approved).
3. Broader page-class coverage beyond these five pages.
4. Product decision on solid-protecting entire Yantra image bboxes (white cells stay white on parchment — correct for fidelity, less “see-through” inside diagrams).

**Do not** integrate into Admin / Backend / production Flutter yet.  
**Do not** process all 33 pages in this phase.

**Priority held:** Tamil glyph and Yantra preservation over maximizing transparent area.
