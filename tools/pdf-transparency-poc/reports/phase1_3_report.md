# Phase 1.3 — Embedded image background transparency

Isolated research under `tools/pdf-transparency-poc/`. Original PDF and Phase 1 / 1.1 outputs were not modified. Production Flutter reader was not changed.

The Phase 1.1 Python sources were not in this workspace. Phase 1.3 is a new script, `scripts/04_phase1_3_process.py`, compared against the supplied original PDF and `phase1_1-five-pages-transparent.pdf`.

## Why the white rectangles remained

Phase 1.1 protected each embedded image’s full placement rectangle. That sealed white Yantra cells, and it also sealed the paper around the diagram inside the same rectangle. Android compositing then showed those rectangles as opaque white plates on the parchment.

## What Phase 1.3 does

For each embedded image:

- Detect red/dark horizontal and vertical strokes.
- If spacing is regular, protect only the cell interiors (opaque).
- If the image is grid-like but irregular, keep the whole rectangle opaque.
- Otherwise treat it as an illustration: keep strokes, clear paper.

Page paper is cleared only when it is close to the page white, is not a stroke, is not an uncertain fringe, and is not a protected cell. A drawn page frame separates the content paper from the pixmap edge, so border-flood alone cannot reach it.

## Page results (150 DPI)

| Page | Transparency | Segmented grids | Cell alpha leaks | Protected-cell MAE | Text MAE | SSIM vs original |
| --- | ---: | --- | ---: | ---: | ---: | ---: |
| 1 | 77.55% | 3×3, 5×3 | 0 | 0 | 0 | 0.99819 |
| 7 | 65.37% | 8×9 (dense Yantra) | 0 | 0 | 0 | 0.99703 |
| 25 | 71.85% | 3×4, 4×5, 4×4 | 0 | 0 | 0 | 0.99705 |
| 33 | 75.17% | 4×4, 7×4 | 0 | 0 | 0 | 0.99814 |
| 13 | 70.44% | 4×4, 5×4 | 0 | 0 | 0 | 0.99787 |

Phase 1.1 still had about 372k–649k near-white opaque pixels inside image rectangles. Phase 1.3 residual near-white opaque pixels inside those rectangles, outside protected cells and strokes, is **0** on every tested page.

Yantra-region MAE is about 0.27–0.37 because cleared paper inside the old image box is rebuilt with the page white. Protected cells and foreground text are unchanged (MAE 0).

## Visual check

Parchment previews in `output/phase1_3/page_XX/`:

- Page paper shows the parchment color.
- White cell interiors stay white.
- Red grid lines and Tamil letters inside cells stay opaque.
- Yellow `செய்முறை` highlights stay.
- A thin gray frame remains around several diagrams. That frame is darker than the paper threshold, so it stays opaque. It is not the old full-image white plate.
- Page 7’s dense grid still reads as a complete 9-wide chart. The detector counted 8×9 because one row gap was merged. No cell was opened (0 alpha leaks).

Overlaps of headings and body text match the original page render. They are layout, not a new transparency defect.

## Android

Phase 1.2 already showed that pdfrx 1.0.84 on the physical phone composites soft-mask alpha over parchment. This phase did not install a new build or recapture the phone. The new file is a soft-mask PDF at `output/phase1_3/phase1_3-five-pages-transparent.pdf` (34,022,660 bytes). It is larger than the Phase 1.1 PDF because each page is a full RGBA raster.

## Limits

- Grid class names are not always the nominal 3×3 / 4×4 / 9×9. Extra or merged rules change the count.
- Gray diagram frames and anti-aliased fringes stay opaque.
- Not run on the other 28 pages.
- Not re-verified on the Android device in this pass.

## Decision

**CONDITIONAL GO**

The five pages no longer keep a solid white plate behind the Yantras, and protected cells and Tamil strokes were not opened. Remaining work is the gray frame/fringe, exact grid-count confidence, file size, and a device pass of this new PDF.
