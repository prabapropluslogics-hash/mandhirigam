"""Independent page-7 line count and gray-frame localization.

Full-span rules only: a boundary must survive an opening kernel
that is 55% of the diagram width or height. Glyph strokes do not.
"""

from __future__ import annotations

import json
from pathlib import Path

import cv2
import fitz
import numpy as np
from PIL import Image
from skimage.metrics import structural_similarity

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output" / "phase1_3_1"
PHASE13 = ROOT / "output" / "phase1_3"
ORIG = ROOT / "input" / "original.pdf"
DPI = 150
RECT = (104, 265, 1139, 948)


def full_span_peaks(ink: np.ndarray) -> dict:
    h, w = ink.shape
    horiz = cv2.morphologyEx(
        ink, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_RECT, (max(40, int(w * 0.55)), 1))
    )
    vert = cv2.morphologyEx(
        ink, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_RECT, (1, max(40, int(h * 0.55))))
    )
    def peaks(profile: np.ndarray, min_gap: int) -> list[dict]:
        thresh = max(float(profile.max()) * 0.45, 1)
        idxs = np.where(profile >= thresh)[0]
        if idxs.size == 0:
            return []
        groups = [[int(idxs[0])]]
        for i in idxs[1:]:
            if int(i) - groups[-1][-1] <= 3:
                groups[-1].append(int(i))
            else:
                groups.append([int(i)])
        found = []
        for group in groups:
            y = group[int(np.argmax(profile[group]))]
            found.append({"at": y, "span_px": int(profile[y] / 255), "thickness": len(group)})
        kept = [found[0]]
        for item in found[1:]:
            if item["at"] - kept[-1]["at"] >= min_gap:
                kept.append(item)
            else:
                # Same stroke: keep the stronger span.
                if item["span_px"] > kept[-1]["span_px"]:
                    kept[-1] = item
        return kept

    h_peaks = peaks(horiz.sum(axis=1), 8)
    v_peaks = peaks(vert.sum(axis=0), 8)
    return {
        "h": h_peaks,
        "v": v_peaks,
        "rows": max(0, len(h_peaks) - 1),
        "cols": max(0, len(v_peaks) - 1),
    }


def main() -> None:
    page = fitz.open(ORIG)[6]
    pix = page.get_pixmap(matrix=fitz.Matrix(DPI / 72, DPI / 72), alpha=False, colorspace=fitz.csRGB)
    full = np.frombuffer(pix.samples, dtype=np.uint8).reshape(pix.height, pix.width, 3).copy()
    x0, y0, x1, y1 = RECT
    crop = full[y0:y1, x0:x1]
    hsv = cv2.cvtColor(cv2.cvtColor(crop, cv2.COLOR_RGB2BGR), cv2.COLOR_BGR2HSV)
    ink = (((hsv[:, :, 0] < 12) | (hsv[:, :, 0] > 168)) & (hsv[:, :, 1] > 40) | (hsv[:, :, 2] < 160)).astype(np.uint8) * 255
    grid = full_span_peaks(ink)
    proc = np.array(Image.open(PHASE13 / "page_07" / "phase1_3.png").convert("RGBA"))
    proc_crop = proc[y0:y1, x0:x1]
    rows = []
    hs = [p["at"] for p in grid["h"]]
    vs = [p["at"] for p in grid["v"]]
    for i in range(len(hs) - 1):
        a, b = hs[i], hs[i + 1]
        band = proc_crop[a + 3 : b - 3]
        white = band[:, :, :3].min(axis=2) >= 245
        alpha0 = band[:, :, 3] == 0
        red = (band[:, :, 0] > 140) & (band[:, :, 1] < 120)
        rows.append(
            {
                "row": i + 1,
                "y0": a,
                "y1": b,
                "height": b - a,
                "white_px": int(white.sum()),
                "white_and_transparent_px": int((white & alpha0).sum()),
                "red_px": int(red.sum()),
            }
        )
    # Markup of full-span lines only, numbered.
    canvas = crop.copy()
    for n, p in enumerate(grid["h"], start=1):
        y = p["at"]
        cv2.line(canvas, (0, y), (canvas.shape[1] - 1, y), (220, 0, 0), 2)
        cv2.putText(canvas, f"H{n}", (8, max(16, y - 4)), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (180, 0, 0), 1, cv2.LINE_AA)
    for n, p in enumerate(grid["v"], start=1):
        x = p["at"]
        cv2.line(canvas, (x, 0), (x, canvas.shape[0] - 1), (0, 0, 220), 2)
        cv2.putText(canvas, f"V{n}", (x + 3, 18), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0, 0, 180), 1, cv2.LINE_AA)
    Image.fromarray(canvas).save(OUT / "page_07_fullspan_markup.png")

    # Gray-frame map: opaque pixels whose original color is mid-gray.
    orig = np.array(Image.open(PHASE13 / "page_07" / "original.png").convert("RGB"))
    alpha = proc[:, :, 3]
    mean = orig.mean(axis=2)
    gray = (
        (np.abs(orig[:, :, 0].astype(int) - orig[:, :, 1].astype(int)) < 12)
        & (np.abs(orig[:, :, 1].astype(int) - orig[:, :, 2].astype(int)) < 12)
        & (mean > 150)
        & (mean < 230)
        & (alpha == 255)
    )
    ys, xs = np.where(gray)
    # Tight crop around gray pixels that sit on the yantra outer rule.
    if ys.size:
        gy0, gy1 = int(ys.min()), int(ys.max())
        gx0, gx1 = int(xs.min()), int(xs.max())
    else:
        gy0, gy1, gx0, gx1 = y0, y1, x0, x1
    # 400% of the top-left corner of the yantra border, original vs processed on parchment.
    parchment = np.array([239, 224, 188], np.uint8)
    a = (proc[:, :, 3:4].astype(np.float32) / 255.0)
    on_parchment = np.clip(proc[:, :, :3].astype(np.float32) * a + parchment.astype(np.float32) * (1 - a), 0, 255).astype(np.uint8)
    cx0, cy0, cx1, cy1 = x0 - 8, y0 - 8, x0 + 80, y0 + 80
    for scale, name in ((2, "200"), (4, "400")):
        o = orig[cy0:cy1, cx0:cx1]
        p = on_parchment[cy0:cy1, cx0:cx1]
        pair = np.concatenate([o, p], axis=1)
        zoom = cv2.resize(pair, (pair.shape[1] * scale, pair.shape[0] * scale), interpolation=cv2.INTER_NEAREST)
        Image.fromarray(zoom).save(OUT / f"page_07_frame_corner_{name}.png")
    # A second corner, bottom-right, where a drop shadow would show outside the rule.
    bx0, by0, bx1, by1 = x1 - 70, y1 - 40, min(orig.shape[1], x1 + 24), min(orig.shape[0], y1 + 24)
    for scale, name in ((2, "200"), (4, "400")):
        pair = np.concatenate([orig[by0:by1, bx0:bx1], on_parchment[by0:by1, bx0:bx1]], axis=1)
        zoom = cv2.resize(pair, (pair.shape[1] * scale, pair.shape[0] * scale), interpolation=cv2.INTER_NEAREST)
        Image.fromarray(zoom).save(OUT / f"page_07_frame_br_{name}.png")

    # Optimized vs phase 1.3 alpha and opaque RGB.
    opt = fitz.open(OUT / "phase1_3_1-five-pages-transparent.pdf")
    compare = []
    for index, page_no in enumerate((1, 7, 25, 33, 13)):
        pix = opt[index].get_pixmap(matrix=fitz.Matrix(DPI / 72, DPI / 72), alpha=True, colorspace=fitz.csRGB)
        rgba = np.frombuffer(pix.samples, dtype=np.uint8).reshape(pix.height, pix.width, 4)
        src = np.array(Image.open(PHASE13 / f"page_{page_no:02d}" / "phase1_3.png").convert("RGBA"))
        orig_rgb = np.array(Image.open(PHASE13 / f"page_{page_no:02d}" / "original.png").convert("RGB"))
        alpha_equal = bool(np.array_equal(rgba[:, :, 3], src[:, :, 3]))
        opaque = rgba[:, :, 3] == 255
        rgb_delta = np.abs(rgba[:, :, :3].astype(np.int16) - src[:, :, :3].astype(np.int16))
        white = np.full_like(orig_rgb, 255)
        aa = (rgba[:, :, 3:4].astype(np.float32) / 255.0)
        recon = np.clip(rgba[:, :, :3].astype(np.float32) * aa + white.astype(np.float32) * (1 - aa), 0, 255).astype(np.uint8)
        ssim = float(structural_similarity(orig_rgb, recon, channel_axis=2, data_range=255))
        # Text: dark original pixels. Cells: not recomputed; compare opaque pixels to original.
        text = orig_rgb.min(axis=2) < 80
        text_mae = float(np.abs(orig_rgb[text].astype(np.float32) - recon[text].astype(np.float32)).mean()) if text.any() else 0.0
        compare.append(
            {
                "source_page": page_no,
                "alpha_identical_to_phase1_3": alpha_equal,
                "opaque_rgb_max_delta_vs_phase1_3": int(rgb_delta[opaque].max()) if opaque.any() else 0,
                "transparent_px": int((rgba[:, :, 3] == 0).sum()),
                "ssim_vs_original_on_white": round(ssim, 5),
                "text_mae_vs_original_on_white": round(text_mae, 4),
            }
        )
        if page_no == 7:
            Image.fromarray(on_parchment).save(OUT / "page_07_parchment.png")
    opt.close()

    report = {
        "full_span": grid,
        "row_alpha": rows,
        "gray_bbox": [gx0, gy0, gx1, gy1],
        "gray_px": int(gray.sum()),
        "optimized_vs_phase13": compare,
    }
    (OUT / "geometry.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps({"h": grid["h"], "v_count": len(grid["v"]), "rows": grid["rows"], "cols": grid["cols"]}, indent=2))
    print(json.dumps(rows, indent=2))
    print(json.dumps(compare, indent=2))


if __name__ == "__main__":
    main()
