"""Phase 1.3.1 experimental correction.

Phase 1.3 snapped grid peaks using the gap to the previous raw peak.
A short false peak in front of the real bottom rule made that rule
look short as well, so the last row of the page-7 Yantra was not
protected and its white cells were cleared.

This script changes only that measurement: the gap is taken from the
last peak that was actually kept. Everything else is the Phase 1.3
pipeline. Outputs go to output/phase1_3_1/. Phase 1.3 files are not
written.
"""

from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path

import fitz
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output" / "phase1_3_1"
PHASE13 = ROOT / "output" / "phase1_3"


def load_phase13():
    spec = importlib.util.spec_from_file_location(
        "phase13", ROOT / "scripts" / "04_phase1_3_process.py"
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def peaks_from_last_kept(profile: np.ndarray, min_gap: int) -> list[int]:
    """Same grouping as Phase 1.3, but a rejected peak does not shrink the next gap."""
    if profile.size == 0 or float(profile.max()) < 8:
        return []
    thresh = max(float(profile.max()) * 0.28, float(np.percentile(profile, 92)))
    idxs = np.where(profile >= thresh)[0]
    if idxs.size == 0:
        return []
    groups: list[list[int]] = [[int(idxs[0])]]
    for i in idxs[1:]:
        if int(i) - groups[-1][-1] <= max(2, min_gap // 3):
            groups[-1].append(int(i))
        else:
            groups.append([int(i)])
    peaks = []
    for group in groups:
        peaks.append(group[int(np.argmax(profile[group]))])
    kept = [peaks[0]]
    for peak in peaks[1:]:
        if peak - kept[-1] >= min_gap:
            kept.append(peak)
    if len(kept) >= 4:
        gaps = np.diff(np.array(kept, dtype=np.float32))
        median_gap = float(np.median(gaps))
        snapped = [kept[0]]
        for peak in kept[1:]:
            if peak - snapped[-1] < median_gap * 0.65:
                continue
            snapped.append(int(peak))
        kept = snapped
    return kept


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def pack_pdf(module) -> dict:
    """PNG-compressed RGBA. Fully transparent samples carry no color, so their
    RGB is stored as 0. Opaque samples are copied unchanged."""
    original = fitz.open(module.INPUT_PDF)
    out = fitz.open()
    png_bytes = []
    for page_no in module.PAGES:
        rgba = np.array(Image.open(OUT / f"page_{page_no:02d}" / "phase1_3.png").convert("RGBA"))
        packed = rgba.copy()
        packed[packed[:, :, 3] == 0, :3] = 0
        png_path = OUT / f"page_{page_no:02d}" / "packed.png"
        Image.fromarray(packed).save(png_path, format="PNG", compress_level=9, optimize=True)
        png_bytes.append(png_path.stat().st_size)
        src = original[page_no - 1]
        page = out.new_page(width=src.rect.width, height=src.rect.height)
        page.insert_image(page.rect, filename=str(png_path))
    pdf_path = OUT / "phase1_3_1-five-pages-transparent.pdf"
    out.save(pdf_path, garbage=4, deflate=True, clean=True)
    out.close()
    original.close()
    raw = OUT / "phase1_3-five-pages-transparent.pdf"
    if raw.exists():
        raw.unlink()
    return {"png_bytes": png_bytes, "pdf_bytes": pdf_path.stat().st_size, "sha256": sha256(pdf_path)}


def main() -> None:
    module = load_phase13()
    module.OUT = OUT
    module._peaks = peaks_from_last_kept
    OUT.mkdir(parents=True, exist_ok=True)
    summary = module.process()
    summary["peak_rule"] = "gap measured from the last kept peak"
    summary["pack"] = pack_pdf(module)
    # Page 7 last content row: white pixels between the 9th and 10th full-span rules.
    proc = np.array(Image.open(OUT / "page_07" / "phase1_3.png").convert("RGBA"))
    prev = np.array(Image.open(PHASE13 / "page_07" / "phase1_3.png").convert("RGBA"))
    x0, y0, x1, y1 = 104, 265, 1139, 948
    # Full-span rules measured in the audit, relative to the image crop.
    last_row = proc[y0 + 570 : y0 + 646, x0:x1]
    white = last_row[:, :, :3].min(axis=2) >= 245
    summary["page7_last_row"] = {
        "white_px": int(white.sum()),
        "white_transparent_px": int((white & (last_row[:, :, 3] == 0)).sum()),
        "phase13_white_transparent_px": int(
            (white & (prev[y0 + 570 : y0 + 646, x0:x1, 3] == 0)).sum()
        ),
    }
    newly_cleared = int(((proc[:, :, 3] == 0) & (prev[:, :, 3] == 255)).sum())
    restored = int(((proc[:, :, 3] == 255) & (prev[:, :, 3] == 0)).sum())
    summary["page7_alpha_delta_vs_phase13"] = {
        "newly_transparent_px": newly_cleared,
        "restored_opaque_px": restored,
    }
    summary["alpha_delta_vs_phase13"] = {}
    for page_no in module.PAGES:
        new = np.array(Image.open(OUT / f"page_{page_no:02d}" / "phase1_3.png").convert("RGBA"))
        old = np.array(Image.open(PHASE13 / f"page_{page_no:02d}" / "phase1_3.png").convert("RGBA"))
        summary["alpha_delta_vs_phase13"][str(page_no)] = {
            "newly_transparent_px": int(((new[:, :, 3] == 0) & (old[:, :, 3] == 255)).sum()),
            "restored_opaque_px": int(((new[:, :, 3] == 255) & (old[:, :, 3] == 0)).sum()),
        }
    (OUT / "metrics.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps({
        "pack": summary["pack"],
        "page7_last_row": summary["page7_last_row"],
        "alpha_delta": summary["alpha_delta_vs_phase13"],
        "grids": [
            {
                "page": p["original_page"],
                "classes": [i["grid_class"] for i in p["embedded_images"] if i["mode"] == "segmented"],
                "cell_alpha_zero": p["cell_alpha_zero_px"],
                "text_mae": p["metrics_vs_original_on_paper"]["text_region_mae"],
                "cell_mae": p["metrics_vs_original_on_paper"]["protected_cell_mae"],
                "ssim": p["metrics_vs_original_on_paper"]["ssim"],
                "transparent_pct": p["transparent_pct"],
            }
            for p in summary["pages"]
        ],
    }, indent=2))


if __name__ == "__main__":
    main()
