# Phase 1.3.1 — Geometry audit, gray frames, lossless pack

Isolated work under `tools/pdf-transparency-poc/`. Phase 1.3 outputs were left in place. The original PDF, Phase 1.1 PDF, and production Admin / Backend / Flutter code were not modified. The 25 MB upload limit was not changed. Five pages only: 1, 7, 25, 33, 13.

## 1. Page 7 grid

The dense Yantra (embedded image xref 103) is **9 rows × 9 columns**.

Independent count on the original render at 150 DPI, using only rules that span at least 55% of the diagram:

| | Boundaries | What they bound |
| --- | ---: | --- |
| Horizontal content rules | 10 (y = 30, 89, 150, 224, 291, 360, 435, 502, 570, 646) | 9 rows, each about 59–76 px, each containing Tamil |
| Vertical content rules | 10 (x = 32, 141, 247, 358, 471, 579, 689, 787, 890, 994) | 9 columns, gaps 98–113 px |
| Enclosed cells | 81 | 9 × 9 |
| Outer frame | 1 extra horizontal rule at y = 670, 24 px below the grid, no Tamil | padding inside the drawn frame, not a cell |

Phase 1.3’s label **8×9** was a counting error, not the source drawing. Its snap measured each gap from the previous raw peak. A short false peak just above the real bottom rule made that real rule look short too, so the bottom rule was discarded. The last row then had 50,491 near-white pixels and all 50,491 were transparent. The red glyphs in that row stayed, because they are foreground.

The experimental correction measures the gap from the last peak that was kept. The same image is then **9×9** (10 horizontal lines, 10 vertical lines, 81 cells). The last row’s near-white transparent pixels fall to 3,822, the same side-margin share as the rows above it. Protected-cell alpha leaks stay 0. Markup: `output/phase1_3_1/page_07_fullspan_markup.png`. Last-row close-up (original, Phase 1.3, Phase 1.3.1): `output/phase1_3_1/page_07_last_row_400.png`.

## 2. Thin gray frames

The light gray frame and the offset gray shadow are in the original render. At the page-7 top-left corner, original RGB already shows the gray rule and the shadow; the Phase 1.3.1 composite on parchment keeps both. Outside that frame the paper is transparent, so the parchment shows. The same pattern is at the bottom-right corner.

Opaque mid-gray pixels (channels within 12 of each other, mean 150–230) match the original color on every tested page:

| Page | Opaque mid-gray pixels | Original mean RGB |
| --- | ---: | --- |
| 1 | 44,087 | 194.5, 194.5, 194.5 |
| 7 | 69,662 | 195.9, 195.9, 195.9 |
| 25 | 47,827 | 197.9, 197.9, 197.8 |
| 33 | 48,522 | 194.2, 194.2, 194.2 |
| 13 | 39,662 | 194.9, 194.9, 194.8 |

These pixels were left opaque. Close-ups: `page_07_frame_corner_200.png`, `page_07_frame_corner_400.png`, `page_07_frame_br_200.png`, `page_07_frame_br_400.png`.

## 3. Five-page quality (corrected render)

| Page | Transparency | Segmented grids | Cell alpha leaks | Cell MAE | Text MAE | SSIM vs original on paper |
| --- | ---: | --- | ---: | ---: | ---: | ---: |
| 1 | 77.55% | 3×3, 5×3 | 0 | 0 | 0 | 0.99819 |
| 7 | 63.04% | 9×9 | 0 | 0 | 0 | 0.99829 |
| 25 | 71.85% | 3×4, 4×5, 4×4 | 0 | 0 | 0 | 0.99705 |
| 33 | 75.17% | 4×4, 7×4 | 0 | 0 | 0 | 0.99814 |
| 13 | 70.44% | 4×4, 5×4 | 0 | 0 | 0 | 0.99787 |

## 4. Original versus processed

On pages 1, 25, 33, and 13 the corrected alpha is identical to Phase 1.3. On page 7 the correction restored 50,708 opaque pixels and cleared none. Text-region MAE is 0 on every page. Protected-cell MAE is 0 on every page. The packed PDF’s opaque RGB matches the corrected raster with maximum delta 0, and its alpha matches exactly.

## 5. Why the Phase 1.3 PDF was 34 MB, and what was changed

Each page was inserted as a raw RGBA pixmap at 150 DPI (1241×1754). Five pages of uncompressed samples are about 43.5 MB. Flate on that raw buffer only reached 34,022,660 bytes.

The optimized file is built from the same rasters:

- PNG, compress level 9, optimized.
- Samples whose alpha is 0 are stored with RGB 0. They are already invisible; opaque samples are copied unchanged.
- PyMuPDF `save(garbage=4, deflate=True, clean=True)`.
- No JPEG, no DPI change, no flatten onto white, no dropped soft mask.

## 6. Sizes

| File | Bytes |
| --- | ---: |
| Phase 1.3 five-page PDF | 34,022,660 |
| Phase 1.3.1 five-page PDF | 2,091,599 |
| Backend document ceiling | 26,214,400 (25 × 1024 × 1024) |

2,091,599 is under that ceiling. The ceiling was not edited.

SHA-256 of `phase1_3_1-five-pages-transparent.pdf`:

`dc18c8053f0ef8b3db8b146a562efa0c50dfdfcd934fa476998c15168a335d49`

Original PDF SHA-256 is still `d9d6ebfaea32e221e9a4465980e4cd7feaee8a45dd186d3e8001eb1199d95231`.

## 7. Soft-mask proof

pypdf 6.21.4 opens the file: 5 pages, not encrypted, each MediaBox 595.32 × 841.92 pt, page order 1, 7, 25, 33, 13. PyMuPDF finds one image XObject per page, each 1241×1754, each with `/SMask`. Re-rendering at 150 DPI reproduces the corrected alpha exactly, including fully transparent pixels (1,372,276 on page 7; 1,688,027 on page 1).

## 8. Tamil and Yantra preservation

Text-region MAE is 0. Protected-cell MAE is 0. Cell-interior alpha leaks are 0. The page-7 last row is white again on the parchment preview; the glyphs in that row match the original. Yellow highlights and red grid lines sit in the foreground mask and were not cleared. The gray diagram frame and its shadow remain.

## 9. Artifact paths

- Script: `tools/pdf-transparency-poc/scripts/07_phase1_3_1_correct.py` (peak-gap fix only; the rest is the Phase 1.3 pipeline).
- Audit scripts: `scripts/05_phase1_3_1_audit.py`, `scripts/06_phase1_3_1_geometry.py`.
- PDF: `tools/pdf-transparency-poc/output/phase1_3_1/phase1_3_1-five-pages-transparent.pdf`.
- Metrics: `output/phase1_3_1/metrics.json`, `geometry.json`, `audit.json`.
- Per page: `output/phase1_3_1/page_XX/` with `original.png`, `phase1_1_on_white.png`, `phase1_3.png` (corrected RGBA), `alpha.png`, `checker.png`, `parchment.png`, `zoom_200.png`, `zoom_400.png`, `packed.png`.
- Page 7 evidence: `page_07_fullspan_markup.png`, `page_07_last_row_400.png`, `page_07_frame_corner_400.png`, `page_07_frame_br_400.png`.

Phase 1.3 remains at `output/phase1_3/` (PDF still 34,022,660 bytes, page 7 still recorded there as 8×9).

## 10. Known limitations

- A real row shorter than 65% of the median gap can still be merged. Page 7’s last row was full height, so this case did not apply.
- Grid class names on the other diagrams (3×3, 5×3, 4×5, 7×4, 5×4) were not given the same manual line count as page 7. On these four pages the correction changed no pixels.
- The other 28 pages were not processed.
- The gray frame is original and will still be visible on parchment.
- This pass did not recapture the Android device.

## 11. Recommendation

**GO** for a research run of all 33 pages with `07_phase1_3_1_correct.py`, written to a new output directory, then packed the same way.

The five-page blockers are resolved: the source grid is 9×9 and the missed row is opaque again, the gray frame is original and was kept, and the five-page file is 2.0 MB with a soft mask on every page. The correction restored pixels on page 7 and cleared none on any of the five pages. Keep the per-page cell-leak check on the 33-page run. Do not replace the production reader or change the upload limit as part of that run.
