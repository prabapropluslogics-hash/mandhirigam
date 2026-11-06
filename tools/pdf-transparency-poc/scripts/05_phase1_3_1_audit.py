"""Phase 1.3.1 audit: page-7 geometry, gray frames, lossless PDF pack.

Reads Phase 1.3 artifacts only. Writes output/phase1_3_1/. Does not
overwrite Phase 1.3 or change segmentation.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import cv2
import fitz
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
PHASE13 = ROOT / "output" / "phase1_3"
ORIG = ROOT / "input" / "original.pdf"
OUT = ROOT / "output" / "phase1_3_1"
PAGES = (1, 7, 25, 33, 13)
DPI = 150
YANTRA7 = (104, 265, 1139, 948)  # Phase 1.3 xref 103 pixel rect


def peaks(profile: np.ndarray, min_gap: int, rel: float = 0.28) -> list[int]:
    if profile.size == 0 or float(profile.max()) < 8:
        return []
    thresh = max(float(profile.max()) * rel, float(np.percentile(profile, 90)))
    idxs = np.where(profile >= thresh)[0]
    if idxs.size == 0:
        return []
    groups = [[int(idxs[0])]]
    for i in idxs[1:]:
        if int(i) - groups[-1][-1] <= max(2, min_gap // 4):
            groups[-1].append(int(i))
        else:
            groups.append([int(i)])
    found = []
    for group in groups:
        found.append(group[int(np.argmax(profile[group]))])
    kept = [found[0]]
    for p in found[1:]:
        if p - kept[-1] >= min_gap:
            kept.append(p)
    return kept


def ink_mask(rgb: np.ndarray) -> np.ndarray:
    hsv = cv2.cvtColor(cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR), cv2.COLOR_BGR2HSV)
    hue, sat, val = hsv[:, :, 0], hsv[:, :, 1], hsv[:, :, 2]
    red = ((hue < 12) | (hue > 168)) & (sat > 40) & (val > 30)
    dark = val < 140
    return (red | dark).astype(np.uint8) * 255


def count_grid(rgb: np.ndarray) -> dict:
    ink = ink_mask(rgb)
    h, w = ink.shape
    horiz = cv2.morphologyEx(
        ink, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_RECT, (max(20, w // 30), 1))
    )
    vert = cv2.morphologyEx(
        ink, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_RECT, (1, max(20, h // 30)))
    )
    h_peaks = peaks(horiz.sum(axis=1), max(8, h // 40))
    v_peaks = peaks(vert.sum(axis=0), max(8, w // 40))
    h_gaps = np.diff(h_peaks).tolist() if len(h_peaks) > 1 else []
    v_gaps = np.diff(v_peaks).tolist() if len(v_peaks) > 1 else []
    h_med = float(np.median(h_gaps)) if h_gaps else 0.0
    v_med = float(np.median(v_gaps)) if v_gaps else 0.0

    def split_short(values: list[int], gaps: list[int], median_gap: float) -> dict:
        """A short gap is a double stroke of one boundary, not a new cell."""
        boundaries = []
        doubles = []
        if not values:
            return {"boundaries": [], "double_strokes": []}
        boundaries.append(values[0])
        for nxt, gap in zip(values[1:], gaps):
            if median_gap and gap < median_gap * 0.55:
                doubles.append({"from": boundaries[-1], "to": nxt, "gap": gap})
                boundaries[-1] = nxt
            else:
                boundaries.append(nxt)
        return {"boundaries": boundaries, "double_strokes": doubles}

    h_split = split_short(h_peaks, h_gaps, h_med)
    v_split = split_short(v_peaks, v_gaps, v_med)
    rows = max(0, len(h_split["boundaries"]) - 1)
    cols = max(0, len(v_split["boundaries"]) - 1)
    return {
        "raw_h_peaks": h_peaks,
        "raw_v_peaks": v_peaks,
        "raw_h_gaps": h_gaps,
        "raw_v_gaps": v_gaps,
        "h_median_gap": round(h_med, 2),
        "v_median_gap": round(v_med, 2),
        "h_boundaries": h_split["boundaries"],
        "v_boundaries": v_split["boundaries"],
        "h_double_strokes": h_split["double_strokes"],
        "v_double_strokes": v_split["double_strokes"],
        "rows": rows,
        "cols": cols,
        "cells": rows * cols,
        "intersections": len(h_split["boundaries"]) * len(v_split["boundaries"]),
    }


def markup(rgb: np.ndarray, grid: dict, path: Path) -> None:
    canvas = rgb.copy()
    for y in grid["raw_h_peaks"]:
        cv2.line(canvas, (0, y), (canvas.shape[1] - 1, y), (0, 180, 255), 1)
    for x in grid["raw_v_peaks"]:
        cv2.line(canvas, (x, 0), (x, canvas.shape[0] - 1), (255, 80, 0), 1)
    for y in grid["h_boundaries"]:
        cv2.line(canvas, (0, y), (canvas.shape[1] - 1, y), (220, 0, 0), 2)
    for x in grid["v_boundaries"]:
        cv2.line(canvas, (x, 0), (x, canvas.shape[0] - 1), (0, 0, 220), 2)
    Image.fromarray(canvas).save(path)


def frame_sample(original: np.ndarray, processed: np.ndarray, rect: tuple[int, int, int, int]) -> dict:
    x0, y0, x1, y1 = rect
    h, w = original.shape[:2]
    # 4px ring immediately outside the image rectangle.
    ring = np.zeros((h, w), np.uint8)
    pad = 4
    oy0, oy1 = max(0, y0 - pad), min(h, y0)
    ring[oy0:oy1, max(0, x0 - pad) : min(w, x1 + pad)] = 1
    oy0, oy1 = max(0, y1), min(h, y1 + pad)
    ring[oy0:oy1, max(0, x0 - pad) : min(w, x1 + pad)] = 1
    ox0, ox1 = max(0, x0 - pad), min(w, x0)
    ring[y0:y1, ox0:ox1] = 1
    ox0, ox1 = max(0, x1), min(w, x1 + pad)
    ring[y0:y1, ox0:ox1] = 1
    # 3px ring inside the rectangle, along its edge.
    inner = np.zeros((h, w), np.uint8)
    t = 3
    inner[y0 : min(h, y0 + t), x0:x1] = 1
    inner[max(0, y1 - t) : y1, x0:x1] = 1
    inner[y0:y1, x0 : min(w, x0 + t)] = 1
    inner[y0:y1, max(0, x1 - t) : x1] = 1

    def stats(mask: np.ndarray) -> dict:
        sel = mask > 0
        if not np.any(sel):
            return {}
        orig = original[sel].astype(np.float32)
        proc = processed[sel, :3].astype(np.float32)
        alpha = processed[sel, 3]
        return {
            "pixels": int(sel.sum()),
            "original_mean_rgb": [round(float(v), 2) for v in orig.mean(axis=0)],
            "processed_opaque_mean_rgb": [round(float(v), 2) for v in proc[alpha > 0].mean(axis=0)]
            if np.any(alpha > 0)
            else None,
            "opaque_fraction": round(float((alpha > 0).mean()), 4),
            "original_near_white_fraction": round(float((orig.min(axis=1) >= 245).mean()), 4),
            "max_abs_rgb_where_opaque": round(float(np.abs(orig - proc)[alpha > 0].max()), 2)
            if np.any(alpha > 0)
            else 0.0,
        }

    return {"outside_4px": stats(ring), "inside_edge_3px": stats(inner)}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_optimized(page_pngs: list[Path], original: fitz.Document) -> dict:
    out_pdf = fitz.open()
    sizes = []
    for index, png_path in enumerate(page_pngs):
        rgba = np.array(Image.open(png_path).convert("RGBA"))
        # Display-identical pack: fully transparent pixels do not contribute
        # color. Zeroing them does not change any visible or opaque sample.
        packed = rgba.copy()
        packed[packed[:, :, 3] == 0, :3] = 0
        packed_path = OUT / f"page_{PAGES[index]:02d}_packed.png"
        Image.fromarray(packed).save(packed_path, format="PNG", compress_level=9, optimize=True)
        sizes.append(packed_path.stat().st_size)
        page = original[PAGES[index] - 1]
        new = out_pdf.new_page(width=page.rect.width, height=page.rect.height)
        new.insert_image(new.rect, filename=str(packed_path))
    raw_path = OUT / "phase1_3_1-five-pages-transparent.pdf"
    out_pdf.save(raw_path, garbage=4, deflate=True, clean=True)
    out_pdf.close()
    return {"png_bytes": sizes, "pdf_bytes": raw_path.stat().st_size, "pdf": str(raw_path)}


def verify_pdf(path: Path, originals: list[np.ndarray]) -> dict:
    doc = fitz.open(path)
    pages = []
    for index, page in enumerate(doc):
        pix = page.get_pixmap(matrix=fitz.Matrix(DPI / 72, DPI / 72), alpha=True, colorspace=fitz.csRGB)
        rgba = np.frombuffer(pix.samples, dtype=np.uint8).reshape(pix.height, pix.width, 4)
        src = originals[index]
        if rgba.shape[:2] != src.shape[:2]:
            rgba = cv2.resize(rgba, (src.shape[1], src.shape[0]), interpolation=cv2.INTER_NEAREST)
        opaque = rgba[:, :, 3] == 255
        rgb_delta = np.abs(rgba[:, :, :3].astype(np.int16) - src[:, :, :3].astype(np.int16))
        smask = page.get_contents()
        pages.append(
            {
                "page_index": index,
                "source_page": PAGES[index],
                "pdf_rect": [round(page.rect.width, 2), round(page.rect.height, 2)],
                "pixels": [int(rgba.shape[1]), int(rgba.shape[0])],
                "transparent_pct": round(float((rgba[:, :, 3] == 0).mean() * 100), 2),
                "opaque_rgb_max_delta": int(rgb_delta[opaque].max()) if np.any(opaque) else 0,
                "soft_mask_content_has_smask_hint": "/SMask" in doc.xref_object(page.get_images()[0][0])
                if page.get_images()
                else False,
            }
        )
    text = doc[0].read_contents().decode("latin1", errors="ignore")
    # SMask lives on the image XObject, not the content stream.
    smask_pages = 0
    for page in doc:
        for img in page.get_images(full=True):
            obj = doc.xref_object(img[0])
            if "/SMask" in obj:
                smask_pages += 1
                break
    info = {
        "pages": doc.page_count,
        "pages_with_smask": smask_pages,
        "page_reports": pages,
    }
    doc.close()
    return info


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    original = fitz.open(ORIG)
    page = original[6]
    pix = page.get_pixmap(matrix=fitz.Matrix(DPI / 72, DPI / 72), alpha=False, colorspace=fitz.csRGB)
    full = np.frombuffer(pix.samples, dtype=np.uint8).reshape(pix.height, pix.width, 3).copy()
    x0, y0, x1, y1 = YANTRA7
    crop = full[y0:y1, x0:x1]
    grid = count_grid(crop)
    markup(crop, grid, OUT / "page_07_yantra_markup.png")
    Image.fromarray(crop).save(OUT / "page_07_yantra_original.png")
    # 400% of the bottom band where the short gaps sit.
    if grid["raw_h_peaks"]:
        band_y = max(0, grid["raw_h_peaks"][-3] - 10)
        band = crop[band_y:, :]
        zoom = cv2.resize(band, (band.shape[1] * 2, band.shape[0] * 2), interpolation=cv2.INTER_NEAREST)
        Image.fromarray(zoom).save(OUT / "page_07_bottom_band_200.png")

    frames = {}
    optimized_sources = []
    for page_no in PAGES:
        folder = PHASE13 / f"page_{page_no:02d}"
        orig_img = np.array(Image.open(folder / "original.png").convert("RGB"))
        proc = np.array(Image.open(folder / "phase1_3.png").convert("RGBA"))
        optimized_sources.append(proc)
        # Largest opaque-ink component edge inside the page stands in for the diagram frame.
        alpha = proc[:, :, 3]
        gray = (
            (np.abs(orig_img[:, :, 0].astype(int) - orig_img[:, :, 1].astype(int)) < 12)
            & (np.abs(orig_img[:, :, 1].astype(int) - orig_img[:, :, 2].astype(int)) < 12)
            & (orig_img.mean(axis=2) > 140)
            & (orig_img.mean(axis=2) < 235)
            & (alpha == 255)
        )
        frames[str(page_no)] = {
            "opaque_mid_gray_px": int(gray.sum()),
            "those_pixels_original_mean_rgb": [round(float(v), 2) for v in orig_img[gray].mean(axis=0)]
            if gray.any()
            else None,
            "note": "Mid-gray opaque pixels are already that color in the original render."
            if gray.any()
            else "No mid-gray opaque pixels.",
        }
        # Close-ups already exist in phase 1.3; copy the 400% parchment crop reference path only.
    page7 = np.array(Image.open(PHASE13 / "page_07" / "phase1_3.png").convert("RGBA"))
    frames["7"]["image_rect"] = frame_sample(full, page7, YANTRA7)

    pack = build_optimized([PHASE13 / f"page_{n:02d}" / "phase1_3.png" for n in PAGES], original)
    # verify_pdf compares against phase 1.3 RGBA, not the paper original.
    verification = verify_pdf(Path(pack["pdf"]), optimized_sources)
    original.close()

    before = (PHASE13 / "phase1_3-five-pages-transparent.pdf").stat().st_size
    report = {
        "page7_geometry": grid,
        "page7_conclusion": {
            "rows": grid["rows"],
            "cols": grid["cols"],
            "cells": grid["cells"],
            "counting_rule": "Raw projection peaks, then gaps below 0.55x the median are one thick stroke, not another row.",
        },
        "gray_frames": frames,
        "pdf": {
            "phase1_3_bytes": before,
            "phase1_3_1_bytes": pack["pdf_bytes"],
            "under_25mb": pack["pdf_bytes"] < 25 * 1024 * 1024,
            "sha256": sha256(Path(pack["pdf"])),
            "png_bytes": pack["png_bytes"],
            "method": "PNG compress_level=9, RGB of alpha 0 pixels set to 0, PyMuPDF save garbage=4 deflate=True",
        },
        "verification": verification,
    }
    (OUT / "audit.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps({k: report[k] for k in ("page7_conclusion", "pdf")}, indent=2))
    print("gray7", json.dumps(frames["7"], indent=2)[:2000])


if __name__ == "__main__":
    main()
