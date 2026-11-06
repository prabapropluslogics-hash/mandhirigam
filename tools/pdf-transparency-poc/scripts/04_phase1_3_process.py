"""Phase 1.3 — segment embedded-image paper without opening Yantra cells.

Reads the original PDF only. Writes under output/phase1_3/.
Does not modify the original or Phase 1 / 1.1 artifacts.
"""

from __future__ import annotations

import json
import time
from pathlib import Path

import cv2
import fitz
import numpy as np
from PIL import Image
from skimage.metrics import structural_similarity

ROOT = Path(__file__).resolve().parents[1]
INPUT_PDF = ROOT / "input" / "original.pdf"
PHASE11_PDF = ROOT / "input" / "phase1_1-five-pages-transparent.pdf"
OUT = ROOT / "output" / "phase1_3"
PAGES = (1, 7, 25, 33, 13)  # 1-based original page numbers
DPI = 150
CLEAR_DIST = 12.0
UNCERTAIN_DIST = 26.0
PARCHMENT_RGB = np.array([239, 224, 188], dtype=np.float32)


def render_rgb(page: fitz.Page, dpi: int) -> np.ndarray:
    pix = page.get_pixmap(matrix=fitz.Matrix(dpi / 72, dpi / 72), alpha=False, colorspace=fitz.csRGB)
    return np.frombuffer(pix.samples, dtype=np.uint8).reshape(pix.height, pix.width, 3).copy()


def render_rgba(page: fitz.Page, dpi: int) -> np.ndarray:
    pix = page.get_pixmap(matrix=fitz.Matrix(dpi / 72, dpi / 72), alpha=True, colorspace=fitz.csRGB)
    return np.frombuffer(pix.samples, dtype=np.uint8).reshape(pix.height, pix.width, 4).copy()


def paper_color(rgb: np.ndarray) -> np.ndarray:
    h, w = rgb.shape[:2]
    band = max(8, min(h, w) // 40)
    strips = np.concatenate(
        [
            rgb[:band, :, :].reshape(-1, 3),
            rgb[-band:, :, :].reshape(-1, 3),
            rgb[:, :band, :].reshape(-1, 3),
            rgb[:, -band:, :].reshape(-1, 3),
        ],
        axis=0,
    )
    return np.median(strips, axis=0).astype(np.uint8)


def lab_distance(rgb: np.ndarray, paper_rgb: np.ndarray) -> np.ndarray:
    bgr = cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR)
    lab = cv2.cvtColor(bgr, cv2.COLOR_BGR2LAB).astype(np.float32)
    pref = cv2.cvtColor(paper_rgb.reshape(1, 1, 3)[:, :, ::-1], cv2.COLOR_BGR2LAB).astype(np.float32)[0, 0]
    return np.linalg.norm(lab - pref, axis=2)


def foreground_mask(rgb: np.ndarray) -> np.ndarray:
    hsv = cv2.cvtColor(cv2.cvtColor(rgb, cv2.COLOR_RGB2BGR), cv2.COLOR_BGR2HSV)
    hue, sat, val = hsv[:, :, 0], hsv[:, :, 1], hsv[:, :, 2]
    red = ((hue < 12) | (hue > 168)) & (sat > 50) & (val > 35)
    yellow = (hue > 12) & (hue < 42) & (sat > 40) & (val > 70)
    dark = val < 110
    return (red | yellow | dark).astype(np.uint8) * 255


def image_rects(page: fitz.Page, scale: float, shape: tuple[int, int]) -> list[dict]:
    h, w = shape
    rects = []
    seen = set()
    infos = []
    try:
        infos = page.get_image_info(xrefs=True)
    except TypeError:
        infos = page.get_image_info()
    for info in infos:
        bbox = info.get("bbox")
        if not bbox:
            continue
        x0 = max(0, int(np.floor(bbox[0] * scale)))
        y0 = max(0, int(np.floor(bbox[1] * scale)))
        x1 = min(w, int(np.ceil(bbox[2] * scale)))
        y1 = min(h, int(np.ceil(bbox[3] * scale)))
        key = (x0, y0, x1, y1, int(info.get("xref") or 0))
        if x1 - x0 < 24 or y1 - y0 < 24 or key in seen:
            continue
        seen.add(key)
        rects.append(
            {
                "xref": int(info.get("xref") or 0),
                "bbox_pt": [round(float(v), 2) for v in bbox],
                "rect": [x0, y0, x1, y1],
            }
        )
    return rects


def _peaks(profile: np.ndarray, min_gap: int) -> list[int]:
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
        sl = profile[group]
        peaks.append(group[int(np.argmax(sl))])
    kept = [peaks[0]]
    for p in peaks[1:]:
        if p - kept[-1] >= min_gap:
            kept.append(p)
    if len(kept) >= 4:
        gaps = np.diff(np.array(kept, dtype=np.float32))
        median_gap = float(np.median(gaps))
        snapped = [kept[0]]
        for peak, gap in zip(kept[1:], gaps):
            if gap < median_gap * 0.65:
                continue
            snapped.append(int(peak))
        kept = snapped
    return kept


def _regular(peaks: list[int]) -> bool:
    if len(peaks) < 4:
        return False
    gaps = np.diff(np.array(peaks, dtype=np.float32))
    if float(gaps.mean()) < 4:
        return False
    return float(gaps.std() / gaps.mean()) < 0.38


def detect_grid(ink: np.ndarray) -> tuple[np.ndarray, dict]:
    """Return a cell-interior protect mask and diagnostics for one ROI."""
    h, w = ink.shape
    # Short kernels keep grid strokes and drop glyph-sized marks. A kernel
    # scaled to the full image bbox erases lines that do not span the margin.
    kw = max(12, min(40, w // 18))
    kh = max(12, min(40, h // 18))
    hk = cv2.getStructuringElement(cv2.MORPH_RECT, (kw, 1))
    vk = cv2.getStructuringElement(cv2.MORPH_RECT, (1, kh))
    horiz = cv2.morphologyEx(ink, cv2.MORPH_OPEN, hk)
    vert = cv2.morphologyEx(ink, cv2.MORPH_OPEN, vk)
    h_peaks = _peaks(horiz.sum(axis=1), max(6, h // 24))
    v_peaks = _peaks(vert.sum(axis=0), max(6, w // 24))
    cells = np.zeros((h, w), np.uint8)
    confident = _regular(h_peaks) and _regular(v_peaks)
    n_cells = 0
    if confident:
        for yi in range(len(h_peaks) - 1):
            for xi in range(len(v_peaks) - 1):
                y0, y1 = h_peaks[yi], h_peaks[yi + 1]
                x0, x1 = v_peaks[xi], v_peaks[xi + 1]
                if y1 - y0 < 6 or x1 - x0 < 6:
                    continue
                inset = 2
                cells[y0 + inset : y1 - inset, x0 + inset : x1 - inset] = 255
                n_cells += 1
        if n_cells < 4:
            confident = False
            cells[:] = 0
    rows = max(0, len(h_peaks) - 1)
    cols = max(0, len(v_peaks) - 1)
    return cells, {
        "confident": confident,
        "h_lines": len(h_peaks),
        "v_lines": len(v_peaks),
        "rows": rows,
        "cols": cols,
        "cells": n_cells,
        "grid_class": f"{rows}x{cols}" if confident else "unresolved",
    }


def flood_clear(candidate: np.ndarray) -> np.ndarray:
    """Keep only candidate pixels connected to the page border."""
    binary = (candidate > 0).astype(np.uint8)
    n_labels, labels = cv2.connectedComponents(binary, connectivity=4)
    if n_labels <= 1:
        return np.zeros_like(candidate)
    border = np.unique(
        np.concatenate(
            [labels[0, :], labels[-1, :], labels[:, 0], labels[:, -1]]
        )
    )
    border = border[border != 0]
    if border.size == 0:
        return np.zeros_like(candidate)
    cleared = np.isin(labels, border)
    return cleared.astype(np.uint8) * 255


def composite(rgb: np.ndarray, alpha: np.ndarray, bg: np.ndarray) -> np.ndarray:
    a = (alpha.astype(np.float32) / 255.0)[..., None]
    return np.clip(rgb.astype(np.float32) * a + bg.astype(np.float32) * (1.0 - a), 0, 255).astype(np.uint8)


def checker(h: int, w: int, cell: int = 16) -> np.ndarray:
    yy, xx = np.indices((h, w))
    odd = ((yy // cell) + (xx // cell)) & 1
    img = np.empty((h, w, 3), np.uint8)
    img[:] = (232, 232, 232)
    img[odd == 1] = (176, 176, 176)
    return img


def metrics(original: np.ndarray, recon: np.ndarray, masks: dict[str, np.ndarray]) -> dict:
    ssim = float(structural_similarity(original, recon, channel_axis=2, data_range=255))
    diff = np.abs(original.astype(np.float32) - recon.astype(np.float32))
    mae = float(diff.mean())
    rmse = float(np.sqrt((diff ** 2).mean()))

    def region(name: str) -> float:
        m = masks[name] > 0
        if not np.any(m):
            return 0.0
        return float(diff[m].mean())

    return {
        "ssim": round(ssim, 5),
        "mae": round(mae, 4),
        "rmse": round(rmse, 4),
        "yantra_region_mae": round(region("yantra"), 4),
        "protected_cell_mae": round(region("cells"), 4),
        "text_region_mae": round(region("text"), 4),
    }


def save_zoom(rgb_or_rgba: np.ndarray, rect: list[int] | None, path: Path, scale: int) -> None:
    if rect is None:
        h, w = rgb_or_rgba.shape[:2]
        rect = [w // 4, h // 4, 3 * w // 4, 3 * h // 4]
    x0, y0, x1, y1 = rect
    crop = rgb_or_rgba[y0:y1, x0:x1]
    if crop.size == 0:
        return
    zoomed = cv2.resize(crop, (crop.shape[1] * scale, crop.shape[0] * scale), interpolation=cv2.INTER_NEAREST)
    # Keep a readable window, not a multi-megapixel dump.
    max_side = 1400
    if max(zoomed.shape[:2]) > max_side:
        f = max_side / max(zoomed.shape[:2])
        zoomed = cv2.resize(zoomed, (int(zoomed.shape[1] * f), int(zoomed.shape[0] * f)), interpolation=cv2.INTER_NEAREST)
    Image.fromarray(zoomed).save(path)


def process() -> dict:
    OUT.mkdir(parents=True, exist_ok=True)
    original = fitz.open(INPUT_PDF)
    phase11 = fitz.open(PHASE11_PDF)
    out_pdf = fitz.open()
    report_pages = []
    t0 = time.perf_counter()

    for index, page_no in enumerate(PAGES):
        page_t = time.perf_counter()
        page = original[page_no - 1]
        rgb = render_rgb(page, DPI)
        h, w = rgb.shape[:2]
        paper = paper_color(rgb)
        dist = lab_distance(rgb, paper)
        fg = foreground_mask(rgb)
        near = dist <= CLEAR_DIST
        uncertain = (dist > CLEAR_DIST) & (dist <= UNCERTAIN_DIST)
        scale = DPI / 72.0
        rects = image_rects(page, scale, (h, w))

        protect = np.zeros((h, w), np.uint8)
        image_mask = np.zeros((h, w), np.uint8)
        cell_mask = np.zeros((h, w), np.uint8)
        image_reports = []

        for info in rects:
            x0, y0, x1, y1 = info["rect"]
            image_mask[y0:y1, x0:x1] = 255
            roi_ink = fg[y0:y1, x0:x1]
            cells, diag = detect_grid(roi_ink)
            if diag["confident"]:
                cell_mask[y0:y1, x0:x1] = np.maximum(cell_mask[y0:y1, x0:x1], cells)
                protect[y0:y1, x0:x1] = np.maximum(protect[y0:y1, x0:x1], cells)
                mode = "segmented"
            elif diag["h_lines"] >= 4 and diag["v_lines"] >= 4:
                # Grid-like but not regular enough to open individual cells.
                protect[y0:y1, x0:x1] = 255
                mode = "opaque_fallback"
            else:
                # Illustration or text image: keep strokes, clear paper.
                mode = "ink_only"
            area = (y1 - y0) * (x1 - x0)
            image_reports.append(
                {
                    **info,
                    **diag,
                    "mode": mode,
                    "area_px": int(area),
                }
            )

        # Vector grids outside embedded images: protect enclosed cells only
        # when the same regular-line test succeeds. Otherwise leave them to
        # foreground/uncertain rules.
        outside = (image_mask == 0).astype(np.uint8) * 255
        outside_ink = cv2.bitwise_and(fg, outside)
        # Search a few large connected line regions rather than the whole page.
        line_kernel_h = cv2.getStructuringElement(cv2.MORPH_RECT, (31, 1))
        line_kernel_v = cv2.getStructuringElement(cv2.MORPH_RECT, (1, 31))
        lines = cv2.bitwise_or(
            cv2.morphologyEx(outside_ink, cv2.MORPH_OPEN, line_kernel_h),
            cv2.morphologyEx(outside_ink, cv2.MORPH_OPEN, line_kernel_v),
        )
        n_labels, labels, stats, _ = cv2.connectedComponentsWithStats(lines, connectivity=8)
        vector_grids = []
        for label in range(1, n_labels):
            x, y, bw, bh, area = stats[label]
            if area < 400 or bw < 40 or bh < 40:
                continue
            pad = 4
            rx0, ry0 = max(0, x - pad), max(0, y - pad)
            rx1, ry1 = min(w, x + bw + pad), min(h, y + bh + pad)
            cells, diag = detect_grid(fg[ry0:ry1, rx0:rx1])
            if not diag["confident"]:
                continue
            cell_mask[ry0:ry1, rx0:rx1] = np.maximum(cell_mask[ry0:ry1, rx0:rx1], cells)
            protect[ry0:ry1, rx0:rx1] = np.maximum(protect[ry0:ry1, rx0:rx1], cells)
            vector_grids.append({"rect": [int(rx0), int(ry0), int(rx1), int(ry1)], **diag})

        # Page content sits inside a drawn frame, so paper is not connected to
        # the pixmap border. Clear every confidently paper-like pixel that is
        # not a stroke, an uncertain fringe, or a protected cell. Enclosed
        # Yantra cells stay opaque because they are in `protect`.
        clear = near & (fg == 0) & ~uncertain & (protect == 0)
        alpha = np.full((h, w), 255, np.uint8)
        alpha[clear] = 0

        # Opaque white still inside an embedded image = residual rectangle.
        white_inside = (image_mask > 0) & (dist <= CLEAR_DIST) & (alpha == 255) & (cell_mask == 0) & (fg == 0)
        rgba = np.dstack([rgb, alpha])
        paper_bg = np.empty_like(rgb)
        paper_bg[:] = paper
        recon = composite(rgb, alpha, paper_bg)
        parch = np.empty_like(rgb)
        parch[:] = PARCHMENT_RGB
        text_mask = (fg > 0) & (cell_mask == 0)
        page_metrics = metrics(
            rgb,
            recon,
            {"yantra": image_mask, "cells": cell_mask, "text": text_mask.astype(np.uint8) * 255},
        )

        # Phase 1.1 comparison at the same DPI (page order matches PAGES).
        p11 = render_rgba(phase11[index], DPI)
        if p11.shape[0] != h or p11.shape[1] != w:
            p11 = cv2.resize(p11, (w, h), interpolation=cv2.INTER_NEAREST)
        p11_on_white = composite(p11[:, :, :3], p11[:, :, 3], np.full_like(rgb, 255))
        p11_white_rect = (image_mask > 0) & (lab_distance(p11_on_white, np.array([255, 255, 255], np.uint8)) <= 10)
        content_diff = np.abs(rgb.astype(np.int16) - p11_on_white.astype(np.int16)).mean(axis=2)
        introduced = float((content_diff > 12).mean() * 100)

        page_dir = OUT / f"page_{page_no:02d}"
        page_dir.mkdir(parents=True, exist_ok=True)
        Image.fromarray(rgb).save(page_dir / "original.png")
        Image.fromarray(p11_on_white).save(page_dir / "phase1_1_on_white.png")
        Image.fromarray(rgba).save(page_dir / "phase1_3.png")
        Image.fromarray(alpha).save(page_dir / "alpha.png")
        Image.fromarray(composite(rgb, alpha, checker(h, w))).save(page_dir / "checker.png")
        Image.fromarray(composite(rgb, alpha, parch)).save(page_dir / "parchment.png")
        focus = None
        if image_reports:
            focus = max(image_reports, key=lambda item: item["area_px"])["rect"]
        elif vector_grids:
            focus = vector_grids[0]["rect"]
        save_zoom(composite(rgb, alpha, parch), focus, page_dir / "zoom_200.png", 2)
        save_zoom(composite(rgb, alpha, parch), focus, page_dir / "zoom_400.png", 4)

        pix = fitz.Pixmap(fitz.csRGB, w, h, rgba.tobytes(), True)
        new_page = out_pdf.new_page(width=page.rect.width, height=page.rect.height)
        new_page.insert_image(new_page.rect, pixmap=pix)

        transparent_pct = round(float((alpha == 0).mean() * 100), 2)
        report_pages.append(
            {
                "original_page": page_no,
                "seconds": round(time.perf_counter() - page_t, 2),
                "size_px": [w, h],
                "paper_rgb": paper.tolist(),
                "transparent_pct": transparent_pct,
                "embedded_images": image_reports,
                "vector_grids": vector_grids,
                "cell_alpha_zero_px": int(((cell_mask > 0) & (alpha == 0)).sum()),
                "residual_opaque_paper_px_in_images": int(white_inside.sum()),
                "phase11_near_white_px_in_images": int(p11_white_rect.sum()),
                "phase11_pixel_diff_pct_gt12": round(introduced, 3),
                "metrics_vs_original_on_paper": page_metrics,
                "protected_cell_px": int((cell_mask > 0).sum()),
                "foreground_px": int((fg > 0).sum()),
            }
        )
        print(
            f"page {page_no}: images={len(image_reports)} "
            f"segmented={sum(1 for i in image_reports if i['mode']=='segmented')} "
            f"fallback={sum(1 for i in image_reports if i['mode']=='opaque_fallback')} "
            f"transparent={transparent_pct}% cell_mae={page_metrics['protected_cell_mae']} "
            f"text_mae={page_metrics['text_region_mae']}"
        )

    pdf_path = OUT / "phase1_3-five-pages-transparent.pdf"
    out_pdf.save(pdf_path)
    out_pdf.close()
    original.close()
    phase11.close()
    summary = {
        "dpi": DPI,
        "pages": report_pages,
        "elapsed_s": round(time.perf_counter() - t0, 2),
        "pdf_bytes": pdf_path.stat().st_size,
        "clear_dist": CLEAR_DIST,
        "uncertain_dist": UNCERTAIN_DIST,
    }
    (OUT / "metrics.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    return summary


if __name__ == "__main__":
    process()
