"""Phase 2 — all 33 pages with the Phase 1.3.1 peak-gap rule.

A gap below 65% of the median is merged only when it is a double stroke
or a glyph fragment. A full-span rule whose interior holds real ink is
kept, and the page is marked for review. Low-confidence grids stay opaque.

Writes output/phase2_all_33/. Does not touch earlier phase directories,
the original PDF, or production code.
"""

from __future__ import annotations

import argparse
import ctypes
import hashlib
import html
import importlib.util
import json
import time
import tracemalloc
from ctypes import wintypes
from pathlib import Path

import cv2
import fitz
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output" / "phase2_all_33"
PHASE131 = ROOT / "output" / "phase1_3_1"
REPORT_MD = ROOT / "reports" / "phase2_all_33_report.md"
REPORT_HTML = ROOT / "reports" / "phase2_comparison.html"
EXPECTED_SHA = "d9d6ebfaea32e221e9a4465980e4cd7feaee8a45dd186d3e8001eb1199d95231"
REGRESSION_PAGES = (1, 7, 25, 33, 13)


class PROCESS_MEMORY_COUNTERS(ctypes.Structure):
    _fields_ = [
        ("cb", wintypes.DWORD),
        ("PageFaultCount", wintypes.DWORD),
        ("PeakWorkingSetSize", ctypes.c_size_t),
        ("WorkingSetSize", ctypes.c_size_t),
        ("QuotaPeakPagedPoolUsage", ctypes.c_size_t),
        ("QuotaPagedPoolUsage", ctypes.c_size_t),
        ("QuotaPeakNonPagedPoolUsage", ctypes.c_size_t),
        ("QuotaNonPagedPoolUsage", ctypes.c_size_t),
        ("PagefileUsage", ctypes.c_size_t),
        ("PeakPagefileUsage", ctypes.c_size_t),
    ]


def working_set() -> tuple[int, int]:
    counters = PROCESS_MEMORY_COUNTERS()
    counters.cb = ctypes.sizeof(counters)
    ctypes.windll.psapi.GetProcessMemoryInfo(
        ctypes.windll.kernel32.GetCurrentProcess(), ctypes.byref(counters), counters.cb
    )
    return int(counters.WorkingSetSize), int(counters.PeakWorkingSetSize)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def load_phase13():
    spec = importlib.util.spec_from_file_location("phase13", ROOT / "scripts" / "04_phase1_3_process.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _group_peaks(profile: np.ndarray, min_gap: int) -> list[int]:
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
    peaks = [group[int(np.argmax(profile[group]))] for group in groups]
    kept = [peaks[0]]
    for peak in peaks[1:]:
        if peak - kept[-1] >= min_gap:
            kept.append(peak)
    return kept


def snap_with_short_rows(profile: np.ndarray, kept: list[int], ink: np.ndarray, axis: int) -> tuple[list[int], list[dict]]:
    """Phase 1.3.1 snap, plus a keep for a real short row.

    axis 0: horizontal rules (profile along y). axis 1: vertical rules.
    """
    notes: list[dict] = []
    if len(kept) < 4:
        return kept, notes
    median_gap = float(np.median(np.diff(np.array(kept, dtype=np.float32))))
    thresh = median_gap * 0.65
    span_limit = ink.shape[1] if axis == 0 else ink.shape[0]
    snapped = [kept[0]]
    for peak in kept[1:]:
        gap = peak - snapped[-1]
        if gap >= thresh:
            snapped.append(int(peak))
            continue
        span = float(profile[peak]) / 255.0
        full = span >= 0.55 * span_limit
        if axis == 0:
            a, b = snapped[-1] + 2, peak - 2
            interior = ink[a:b] if b > a else ink[0:0]
            spread = float((interior.max(axis=0) > 0).mean()) if interior.size else 0.0
        else:
            a, b = snapped[-1] + 2, peak - 2
            interior = ink[:, a:b] if b > a else ink[:, 0:0]
            spread = float((interior.max(axis=1) > 0).mean()) if interior.size else 0.0
        ink_px = int((interior > 0).sum()) if interior.size else 0
        keep = full and gap >= 10 and ink_px >= 40 and spread >= 0.25
        note = {
            "axis": "h" if axis == 0 else "v",
            "from": int(snapped[-1]),
            "to": int(peak),
            "gap": int(gap),
            "median_gap": round(median_gap, 2),
            "span_px": int(span),
            "full_span": bool(full),
            "interior_ink_px": ink_px,
            "spread": round(spread, 3),
            "decision": "kept_short_row" if keep else "merged_double_or_fragment",
        }
        notes.append(note)
        if keep:
            snapped.append(int(peak))
    return snapped, notes


def detect_grid_phase2(ink: np.ndarray) -> tuple[np.ndarray, dict]:
    """Same cell protect as Phase 1.3, with the short-row guard on the snap."""
    h, w = ink.shape
    kw = max(12, min(40, w // 18))
    kh = max(12, min(40, h // 18))
    horiz = cv2.morphologyEx(ink, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_RECT, (kw, 1)))
    vert = cv2.morphologyEx(ink, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_RECT, (1, kh)))
    h_raw = _group_peaks(horiz.sum(axis=1), max(6, h // 24))
    v_raw = _group_peaks(vert.sum(axis=0), max(6, w // 24))
    # Interior ink is measured on the source mask so a real short row of
    # Tamil is kept, while a double stroke (empty interior) is still merged.
    h_peaks, h_notes = snap_with_short_rows(horiz.sum(axis=1), h_raw, ink, 0)
    v_peaks, v_notes = snap_with_short_rows(vert.sum(axis=0), v_raw, ink, 1)
    cells = np.zeros((h, w), np.uint8)
    confident = _regular_local(h_peaks) and _regular_local(v_peaks)
    n_cells = 0
    if confident:
        for yi in range(len(h_peaks) - 1):
            for xi in range(len(v_peaks) - 1):
                y0, y1 = h_peaks[yi], h_peaks[yi + 1]
                x0, x1 = v_peaks[xi], v_peaks[xi + 1]
                if y1 - y0 < 6 or x1 - x0 < 6:
                    continue
                cells[y0 + 2 : y1 - 2, x0 + 2 : x1 - 2] = 255
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
        "short_rows": h_notes + v_notes,
        "h_peaks": h_peaks,
        "v_peaks": v_peaks,
    }


def _regular_local(peaks: list[int]) -> bool:
    if len(peaks) < 4:
        return False
    gaps = np.diff(np.array(peaks, dtype=np.float32))
    if float(gaps.mean()) < 4:
        return False
    return float(gaps.std() / gaps.mean()) < 0.38


def judge(page: dict) -> tuple[str, list[str]]:
    reasons: list[str] = []
    if page["fg_alpha_zero_px"] > 0:
        reasons.append(f"foreground pixels cleared: {page['fg_alpha_zero_px']}")
    if page["cell_alpha_zero_px"] > 0:
        reasons.append(f"protected-cell alpha leak: {page['cell_alpha_zero_px']}")
    if page["metrics_vs_original_on_paper"]["text_region_mae"] > 0:
        reasons.append("text-region MAE above 0")
    if page["metrics_vs_original_on_paper"]["protected_cell_mae"] > 0:
        reasons.append("protected-cell MAE above 0")
    if page["opaque_rgb_max_delta"] > 0:
        reasons.append("opaque color changed")
    if reasons:
        return "FAIL", reasons
    review: list[str] = []
    for image in page["embedded_images"]:
        if image["mode"] == "opaque_fallback":
            review.append(f"xref {image['xref']} kept opaque ({image['h_lines']}h/{image['v_lines']}v, not regular)")
        for note in image.get("short_rows") or []:
            if note["decision"] == "kept_short_row":
                review.append(
                    f"xref {image['xref']} short {note['axis']} row kept, gap {note['gap']} vs median {note['median_gap']}"
                )
            elif note.get("full_span") and note["interior_ink_px"] >= 40:
                review.append(
                    f"xref {image['xref']} full-span short {note['axis']} gap {note['gap']} merged with interior ink {note['interior_ink_px']}"
                )
    for grid in page["vector_grids"]:
        for note in grid.get("short_rows") or []:
            if note["decision"] == "kept_short_row":
                review.append(f"vector grid short {note['axis']} row kept, gap {note['gap']}")
    if review:
        return "NEEDS_REVIEW", review
    return "PASS", []


def process_pages(module, page_numbers: list[int]) -> dict:
    OUT.mkdir(parents=True, exist_ok=True)
    module.detect_grid = detect_grid_phase2
    original = fitz.open(module.INPUT_PDF)
    if original.page_count != 33:
        raise SystemExit(f"expected 33 pages, found {original.page_count}")
    thumbs: list[Image.Image] = []
    pages = []
    t0 = time.perf_counter()
    peak_ws = 0
    for page_no in page_numbers:
        page_t = time.perf_counter()
        page = original[page_no - 1]
        rgb = module.render_rgb(page, module.DPI)
        h, w = rgb.shape[:2]
        paper = module.paper_color(rgb)
        dist = module.lab_distance(rgb, paper)
        fg = module.foreground_mask(rgb)
        near = dist <= module.CLEAR_DIST
        uncertain = (dist > module.CLEAR_DIST) & (dist <= module.UNCERTAIN_DIST)
        rects = module.image_rects(page, module.DPI / 72.0, (h, w))
        protect = np.zeros((h, w), np.uint8)
        image_mask = np.zeros((h, w), np.uint8)
        cell_mask = np.zeros((h, w), np.uint8)
        image_reports = []
        for info in rects:
            x0, y0, x1, y1 = info["rect"]
            image_mask[y0:y1, x0:x1] = 255
            cells, diag = module.detect_grid(fg[y0:y1, x0:x1])
            if diag["confident"]:
                cell_mask[y0:y1, x0:x1] = np.maximum(cell_mask[y0:y1, x0:x1], cells)
                protect[y0:y1, x0:x1] = np.maximum(protect[y0:y1, x0:x1], cells)
                mode = "segmented"
            elif diag["h_lines"] >= 4 and diag["v_lines"] >= 4:
                protect[y0:y1, x0:x1] = 255
                mode = "opaque_fallback"
            else:
                mode = "ink_only"
            image_reports.append({**info, **diag, "mode": mode, "area_px": int((y1 - y0) * (x1 - x0))})
        outside = (image_mask == 0).astype(np.uint8) * 255
        outside_ink = cv2.bitwise_and(fg, outside)
        lines = cv2.bitwise_or(
            cv2.morphologyEx(outside_ink, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_RECT, (31, 1))),
            cv2.morphologyEx(outside_ink, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_RECT, (1, 31))),
        )
        n_labels, _labels, stats, _ = cv2.connectedComponentsWithStats(lines, connectivity=8)
        vector_grids = []
        for label in range(1, n_labels):
            x, y, bw, bh, area = stats[label]
            if area < 400 or bw < 40 or bh < 40:
                continue
            rx0, ry0 = max(0, x - 4), max(0, y - 4)
            rx1, ry1 = min(w, x + bw + 4), min(h, y + bh + 4)
            cells, diag = module.detect_grid(fg[ry0:ry1, rx0:rx1])
            if not diag["confident"]:
                continue
            cell_mask[ry0:ry1, rx0:rx1] = np.maximum(cell_mask[ry0:ry1, rx0:rx1], cells)
            protect[ry0:ry1, rx0:rx1] = np.maximum(protect[ry0:ry1, rx0:rx1], cells)
            vector_grids.append({"rect": [int(rx0), int(ry0), int(rx1), int(ry1)], **diag})
        clear = near & (fg == 0) & ~uncertain & (protect == 0)
        alpha = np.full((h, w), 255, np.uint8)
        alpha[clear] = 0
        rgba = np.dstack([rgb, alpha])
        recon = module.composite(rgb, alpha, np.broadcast_to(paper, rgb.shape).copy())
        parch = np.broadcast_to(module.PARCHMENT_RGB.astype(np.uint8), rgb.shape).copy()
        text_mask = ((fg > 0) & (cell_mask == 0)).astype(np.uint8) * 255
        page_metrics = module.metrics(rgb, recon, {"yantra": image_mask, "cells": cell_mask, "text": text_mask})
        opaque = alpha == 255
        rgb_delta = np.abs(rgba[:, :, :3].astype(np.int16) - rgb.astype(np.int16))
        dense = any(item["mode"] == "segmented" and item["cells"] >= 9 for item in image_reports) or int((fg > 0).sum()) > 8000
        report = {
            "original_page": page_no,
            "seconds": round(time.perf_counter() - page_t, 2),
            "size_px": [w, h],
            "pdf_rect": [round(page.rect.width, 2), round(page.rect.height, 2)],
            "transparent_pct": round(float((alpha == 0).mean() * 100), 2),
            "embedded_images": image_reports,
            "vector_grids": vector_grids,
            "cell_alpha_zero_px": int(((cell_mask > 0) & (alpha == 0)).sum()),
            "fg_alpha_zero_px": int(((fg > 0) & (alpha == 0)).sum()),
            "protected_cell_px": int((cell_mask > 0).sum()),
            "foreground_px": int((fg > 0).sum()),
            "opaque_rgb_max_delta": int(rgb_delta[opaque].max()) if opaque.any() else 0,
            "metrics_vs_original_on_paper": page_metrics,
            "dense_closeup": dense,
        }
        status, notes = judge(report)
        report["status"] = status
        report["notes"] = notes
        page_dir = OUT / f"page_{page_no:02d}"
        page_dir.mkdir(parents=True, exist_ok=True)
        Image.fromarray(rgb).save(page_dir / "original.png", compress_level=3)
        Image.fromarray(rgba).save(page_dir / "rgba.png", compress_level=3)
        Image.fromarray(alpha).save(page_dir / "alpha.png", compress_level=3)
        checker = module.composite(rgb, alpha, module.checker(h, w))
        parchment = module.composite(rgb, alpha, parch)
        Image.fromarray(checker).save(page_dir / "checker.png", compress_level=3)
        Image.fromarray(parchment).save(page_dir / "parchment.png", compress_level=3)
        if dense:
            focus = None
            if image_reports:
                focus = max(image_reports, key=lambda item: item["area_px"])["rect"]
            module.save_zoom(parchment, focus, page_dir / "zoom_400.png", 4)
        thumb = Image.fromarray(parchment).resize((180, int(180 * h / w)), Image.Resampling.BILINEAR)
        draw = ImageDraw.Draw(thumb)
        draw.rectangle((0, 0, 36, 16), fill=(0, 0, 0))
        draw.text((4, 2), str(page_no), fill=(255, 255, 255))
        thumbs.append(thumb)
        pages.append(report)
        _, peak = working_set()
        peak_ws = max(peak_ws, peak)
        print(
            f"page {page_no}: {status} transparent={report['transparent_pct']}% "
            f"cells={report['protected_cell_px']} leaks={report['cell_alpha_zero_px']} "
            f"fg_cleared={report['fg_alpha_zero_px']} {time.perf_counter() - page_t:.1f}s",
            flush=True,
        )
        del rgb, rgba, alpha, checker, parchment, fg, dist
    original.close()
    if len(thumbs) == 33:
        sheet = contact_sheet(thumbs)
        sheet.save(OUT / "contact_sheet.png")
    summary = {
        "dpi": module.DPI,
        "pages": pages,
        "elapsed_s": round(time.perf_counter() - t0, 2),
        "peak_working_set_bytes": peak_ws,
        "short_row_rule": "keep a sub-median gap only when the rule spans >=55% and the interior holds ink",
    }
    (OUT / "metrics.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    return summary


def contact_sheet(thumbs: list[Image.Image]) -> Image.Image:
    cols = 6
    pad = 8
    cell_w = max(thumb.width for thumb in thumbs) + pad
    cell_h = max(thumb.height for thumb in thumbs) + pad
    rows = (len(thumbs) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cell_w, rows * cell_h), (244, 236, 220))
    for index, thumb in enumerate(thumbs):
        r, c = divmod(index, cols)
        sheet.paste(thumb, (c * cell_w + 4, r * cell_h + 4))
    return sheet


def pack_pdf(module, page_numbers: list[int]) -> dict:
    original = fitz.open(module.INPUT_PDF)
    out = fitz.open()
    png_bytes = []
    for page_no in page_numbers:
        rgba = np.array(Image.open(OUT / f"page_{page_no:02d}" / "rgba.png").convert("RGBA"))
        packed = rgba.copy()
        packed[packed[:, :, 3] == 0, :3] = 0
        png_path = OUT / f"page_{page_no:02d}" / "packed.png"
        Image.fromarray(packed).save(png_path, format="PNG", compress_level=9, optimize=True)
        png_bytes.append({"page": page_no, "bytes": png_path.stat().st_size})
        src = original[page_no - 1]
        page = out.new_page(width=src.rect.width, height=src.rect.height)
        page.insert_image(page.rect, filename=str(png_path))
        print(f"packed page {page_no}: {png_path.stat().st_size}", flush=True)
    pdf_path = OUT / "phase2-all-33-transparent.pdf"
    out.save(str(pdf_path), garbage=4, deflate=True, clean=True)
    out.close()
    original.close()
    return {"png": png_bytes, "pdf_bytes": pdf_path.stat().st_size, "sha256": sha256(pdf_path), "path": str(pdf_path)}


def verify_pdf(path: Path, page_numbers: list[int]) -> dict:
    reader_pages = None
    independent = "pymupdf"
    try:
        from pypdf import PdfReader

        reader = PdfReader(str(path))
        reader_pages = len(reader.pages)
        independent = "pypdf"
        boxes = [[round(float(p.mediabox.width), 2), round(float(p.mediabox.height), 2)] for p in reader.pages]
    except Exception as exc:  # noqa: BLE001
        boxes = []
        independent = f"pypdf failed: {exc}"
    doc = fitz.open(path)
    smask = 0
    order_ok = doc.page_count == len(page_numbers)
    for index, page in enumerate(doc):
        images = page.get_images(full=True)
        has = False
        for img in images:
            if "/SMask" in doc.xref_object(img[0]):
                has = True
        if has:
            smask += 1
        if index < len(page_numbers):
            src = fitz.open(ROOT / "input" / "original.pdf")[page_numbers[index] - 1]
            if abs(page.rect.width - src.rect.width) > 0.1 or abs(page.rect.height - src.rect.height) > 0.1:
                order_ok = False
            src.parent.close()
    doc.close()
    return {
        "independent_parser": independent,
        "parser_pages": reader_pages,
        "pymupdf_pages": None,
        "pages_with_smask": smask,
        "boxes": boxes,
        "geometry_matches_source": order_ok,
    }


def regression(summary: dict) -> dict:
    checks = {}
    for page in summary["pages"]:
        page_no = page["original_page"]
        if page_no not in REGRESSION_PAGES:
            continue
        new = np.array(Image.open(OUT / f"page_{page_no:02d}" / "rgba.png").convert("RGBA"))
        old = np.array(Image.open(PHASE131 / f"page_{page_no:02d}" / "phase1_3.png").convert("RGBA"))
        newly = int(((new[:, :, 3] == 0) & (old[:, :, 3] == 255)).sum())
        restored = int(((new[:, :, 3] == 255) & (old[:, :, 3] == 0)).sum())
        grids = [item["grid_class"] for item in page["embedded_images"] if item["mode"] == "segmented"]
        checks[str(page_no)] = {
            "newly_transparent_vs_phase1_3_1": newly,
            "restored_opaque_vs_phase1_3_1": restored,
            "segmented_grids": grids,
            "cell_alpha_zero_px": page["cell_alpha_zero_px"],
            "text_mae": page["metrics_vs_original_on_paper"]["text_region_mae"],
            "cell_mae": page["metrics_vs_original_on_paper"]["protected_cell_mae"],
        }
    page7 = next(page for page in summary["pages"] if page["original_page"] == 7)
    yantra = next((item for item in page7["embedded_images"] if item.get("grid_class") == "9x9"), None)
    checks["page7_geometry"] = {
        "rows": None if yantra is None else yantra["rows"],
        "cols": None if yantra is None else yantra["cols"],
        "cells": None if yantra is None else yantra["cells"],
        "cell_alpha_zero_px": page7["cell_alpha_zero_px"],
        "pass": bool(yantra and yantra["rows"] == 9 and yantra["cols"] == 9 and yantra["cells"] == 81 and page7["cell_alpha_zero_px"] == 0),
    }
    return checks


def write_reports(summary: dict, pack: dict, verification: dict, checks: dict) -> str:
    counts = {"PASS": 0, "FAIL": 0, "NEEDS_REVIEW": 0}
    for page in summary["pages"]:
        counts[page["status"]] += 1
    if counts["FAIL"]:
        decision = "NO-GO"
    elif counts["NEEDS_REVIEW"]:
        decision = "CONDITIONAL GO"
    else:
        decision = "GO"
    lines = [
        "# Phase 2 — all 33 pages",
        "",
        "Research batch only. Original PDF, earlier phase outputs, and production code were not modified. The 25 MB upload limit was not changed. The PDF was not uploaded.",
        "",
        f"**Decision: {decision}**",
        "",
        f"PASS {counts['PASS']} · NEEDS_REVIEW {counts['NEEDS_REVIEW']} · FAIL {counts['FAIL']}",
        "",
        "## Page status",
        "",
        "| Page | Status | Transparency | Grids | Cells | Cell leaks | Text MAE | Cell MAE | SSIM | Seconds |",
        "| ---: | --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for page in summary["pages"]:
        grids = ", ".join(
            item["grid_class"] + ("" if item["mode"] == "segmented" else f" ({item['mode']})")
            for item in page["embedded_images"]
            if item["mode"] != "ink_only" or item["h_lines"] >= 4
        ) or "—"
        metrics = page["metrics_vs_original_on_paper"]
        lines.append(
            f"| {page['original_page']} | {page['status']} | {page['transparent_pct']}% | {grids} | "
            f"{page['protected_cell_px']} | {page['cell_alpha_zero_px']} | {metrics['text_region_mae']} | "
            f"{metrics['protected_cell_mae']} | {metrics['ssim']} | {page['seconds']} |"
        )
    lines += ["", "## Review and failures", ""]
    flagged = [page for page in summary["pages"] if page["status"] != "PASS"]
    if not flagged:
        lines.append("None.")
    for page in flagged:
        lines.append(f"- Page {page['original_page']} **{page['status']}**: " + "; ".join(page["notes"]))
    lines += [
        "",
        "## Regression against Phase 1.3.1",
        "",
        "```json",
        json.dumps(checks, indent=2),
        "```",
        "",
        "## PDF",
        "",
        f"- Bytes: {pack['pdf_bytes']}",
        f"- Under 25 MB: {pack['pdf_bytes'] < 25 * 1024 * 1024}",
        f"- SHA-256: `{pack['sha256']}`",
        f"- Soft-mask pages: {verification['pages_with_smask']}",
        f"- Independent parser: {verification['independent_parser']} pages={verification['parser_pages']}",
        f"- Geometry matches source: {verification['geometry_matches_source']}",
        f"- Elapsed processing seconds: {summary['elapsed_s']}",
        f"- Peak working set bytes: {summary['peak_working_set_bytes']}",
        "- Compression: PNG compress level 9, RGB of alpha-0 samples stored as 0, PyMuPDF deflate garbage=4. No JPEG, no DPI change.",
        "",
        "## Outputs",
        "",
        "- `tools/pdf-transparency-poc/output/phase2_all_33/`",
        "- `tools/pdf-transparency-poc/output/phase2_all_33/phase2-all-33-transparent.pdf`",
        "- `tools/pdf-transparency-poc/output/phase2_all_33/contact_sheet.png`",
        "- `tools/pdf-transparency-poc/output/phase2_all_33/metrics.json`",
        "- `tools/pdf-transparency-poc/reports/phase2_comparison.html`",
        "",
    ]
    REPORT_MD.parent.mkdir(parents=True, exist_ok=True)
    REPORT_MD.write_text("\n".join(lines), encoding="utf-8")
    write_html(summary)
    return decision


def write_html(summary: dict) -> None:
    parts = [
        "<!DOCTYPE html><html><head><meta charset='utf-8'><title>Phase 2 comparison</title>",
        "<style>body{font-family:sans-serif;margin:24px} table{border-collapse:collapse} td,th{border:1px solid #ccc;padding:4px 8px;vertical-align:top}",
        ".PASS{color:#146c2e}.FAIL{color:#9b1c1c}.NEEDS_REVIEW{color:#8a5a00} img{max-width:280px;height:auto}</style></head><body>",
        "<h1>Phase 2 — 33-page comparison</h1>",
        "<p>Original, parchment, checker, alpha. Paths are relative to this report.</p><table>",
        "<tr><th>Page</th><th>Status</th><th>Original</th><th>Parchment</th><th>Checker</th><th>Alpha</th></tr>",
    ]
    for page in summary["pages"]:
        n = f"{page['original_page']:02d}"
        base = f"../output/phase2_all_33/page_{n}"
        zoom = f"<div><a href='{base}/zoom_400.png'>400%</a></div>" if page.get("dense_closeup") else ""
        notes = "<br>".join(html.escape(note) for note in page["notes"])
        parts.append(
            f"<tr><td>{page['original_page']}<div class='{page['status']}'>{page['status']}</div>"
            f"<div>{page['transparent_pct']}%</div>{zoom}<div>{notes}</div></td>"
            f"<td>{html.escape(page['status'])}</td>"
            f"<td><img src='{base}/original.png' alt='original {n}'></td>"
            f"<td><img src='{base}/parchment.png' alt='parchment {n}'></td>"
            f"<td><img src='{base}/checker.png' alt='checker {n}'></td>"
            f"<td><img src='{base}/alpha.png' alt='alpha {n}'></td></tr>"
        )
    parts.append("</table></body></html>")
    REPORT_HTML.write_text("".join(parts), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pages", nargs="*", type=int)
    parser.add_argument("--no-pack", action="store_true")
    args = parser.parse_args()
    source = ROOT / "input" / "original.pdf"
    digest = sha256(source)
    if digest != EXPECTED_SHA:
        raise SystemExit(f"original SHA mismatch: {digest}")
    module = load_phase13()
    page_numbers = args.pages or list(range(1, 34))
    tracemalloc.start()
    summary = process_pages(module, page_numbers)
    if args.no_pack or page_numbers != list(range(1, 34)):
        print(json.dumps({"pages": [p["original_page"] for p in summary["pages"]], "status": [p["status"] for p in summary["pages"]]}))
        return
    pack = pack_pdf(module, page_numbers)
    verification = verify_pdf(Path(pack["path"]), page_numbers)
    doc = fitz.open(pack["path"])
    verification["pymupdf_pages"] = doc.page_count
    doc.close()
    checks = regression(summary)
    summary["pack"] = pack
    summary["verification"] = verification
    summary["regression"] = checks
    decision = write_reports(summary, pack, verification, checks)
    summary["decision"] = decision
    (OUT / "metrics.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps({"decision": decision, "pdf_bytes": pack["pdf_bytes"], "sha256": pack["sha256"], "regression_page7": checks["page7_geometry"], "smask": verification["pages_with_smask"]}, indent=2))


if __name__ == "__main__":
    main()
