"""Compare a fresh Phase 2 output directory with the historical baseline."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image

from .fixture import CATALOG_FINGERPRINT, OUTPUT_DIR, SOURCE_PAGE_COUNT
from .paths import HarnessPaths
from .validate_package import catalog_fingerprint
from .validate_source import sha256_file


def _page_summary(paths: HarnessPaths, page: int) -> dict:
    packed = paths.packed_png(page)
    original = paths.original_png(page)
    summary: dict = {
        "page": page,
        "packed_exists": packed.is_file(),
        "original_exists": original.is_file(),
    }
    if not packed.is_file():
        return summary
    with Image.open(packed) as image:
        summary["mode"] = image.mode
        summary["size"] = list(image.size)
        extrema = image.getextrema() if image.mode == "RGBA" else None
        summary["alpha_extrema"] = None if extrema is None else list(extrema[3])
    arr = np.asarray(Image.open(packed).convert("RGBA"))
    alpha = arr[:, :, 3]
    summary["bytes"] = packed.stat().st_size
    summary["sha256"] = sha256_file(packed)
    summary["transparent_pct"] = round(float((alpha == 0).mean() * 100), 4)
    summary["opaque_px"] = int((alpha == 255).sum())
    return summary


def compare(fresh_dir: Path, historical_dir: Path = OUTPUT_DIR) -> dict:
    fresh = HarnessPaths.for_output_dir(fresh_dir)
    hist = HarnessPaths(
        output_dir=historical_dir,
        metrics_json=historical_dir / "metrics.json",
    )
    fresh_metrics = {}
    hist_metrics = {}
    if fresh.metrics_json.is_file():
        fresh_metrics = json.loads(fresh.metrics_json.read_text(encoding="utf-8"))
    if hist.metrics_json.is_file():
        hist_metrics = json.loads(hist.metrics_json.read_text(encoding="utf-8"))

    fresh_pages = {
        int(page["original_page"]): page for page in fresh_metrics.get("pages") or []
    }
    hist_pages = {
        int(page["original_page"]): page for page in hist_metrics.get("pages") or []
    }

    pages = []
    identical = 0
    for page in range(1, SOURCE_PAGE_COUNT + 1):
        f = _page_summary(fresh, page)
        h = _page_summary(hist, page)
        fm = fresh_pages.get(page, {})
        hm = hist_pages.get(page, {})
        byte_identical = f.get("sha256") == h.get("sha256")
        if byte_identical:
            identical += 1
        # Structural equivalence from metrics.
        f_grids = [
            item.get("grid_class")
            for item in fm.get("embedded_images") or []
            if item.get("mode") == "segmented"
        ]
        h_grids = [
            item.get("grid_class")
            for item in hm.get("embedded_images") or []
            if item.get("mode") == "segmented"
        ]
        structural = (
            fm.get("status") == hm.get("status")
            and f_grids == h_grids
            and fm.get("cell_alpha_zero_px") == hm.get("cell_alpha_zero_px")
            and fm.get("fg_alpha_zero_px") == hm.get("fg_alpha_zero_px")
            and f.get("size") == h.get("size")
            and f.get("mode") == h.get("mode")
        )
        # Pixel equivalence of opaque RGB when both originals/packed exist.
        pixel_note = "n/a"
        if f["packed_exists"] and h["packed_exists"] and not byte_identical:
            fa = np.asarray(Image.open(fresh.packed_png(page)).convert("RGBA"))
            ha = np.asarray(Image.open(hist.packed_png(page)).convert("RGBA"))
            if fa.shape == ha.shape:
                alpha_equal = bool(np.array_equal(fa[:, :, 3], ha[:, :, 3]))
                opaque = fa[:, :, 3] == 255
                rgb_equal = (
                    bool(np.array_equal(fa[:, :, :3][opaque], ha[:, :, :3][opaque]))
                    if opaque.any()
                    else alpha_equal
                )
                if alpha_equal and rgb_equal:
                    pixel_note = "alpha+opaque_rgb_identical"
                elif alpha_equal:
                    pixel_note = "alpha_identical_rgb_differs"
                else:
                    pixel_note = (
                        f"alpha_diff_px="
                        f"{int((fa[:, :, 3] != ha[:, :, 3]).sum())}"
                    )
            else:
                pixel_note = "shape_mismatch"
        elif byte_identical:
            pixel_note = "byte_identical"

        if byte_identical:
            classification = "byte_identical"
        elif structural and pixel_note in {
            "alpha+opaque_rgb_identical",
            "byte_identical",
        }:
            classification = "structurally_equivalent_byte_different"
        elif structural:
            classification = "structurally_equivalent_pixels_differ"
        else:
            classification = "unexpected_difference"

        pages.append(
            {
                "page": page,
                "classification": classification,
                "byte_identical": byte_identical,
                "structural_match": structural,
                "pixel_note": pixel_note,
                "fresh_status": fm.get("status"),
                "historical_status": hm.get("status"),
                "fresh_grids": f_grids,
                "historical_grids": h_grids,
                "fresh_transparent_pct": fm.get("transparent_pct", f.get("transparent_pct")),
                "historical_transparent_pct": hm.get(
                    "transparent_pct", h.get("transparent_pct")
                ),
                "fresh_sha256": f.get("sha256"),
                "historical_sha256": h.get("sha256"),
                "fresh_bytes": f.get("bytes"),
                "historical_bytes": h.get("bytes"),
            }
        )

    fresh_digests = [
        page["fresh_sha256"]
        for page in pages
        if page.get("fresh_sha256")
    ]
    hist_digests = [
        page["historical_sha256"]
        for page in pages
        if page.get("historical_sha256")
    ]
    return {
        "fresh_dir": str(fresh.output_dir),
        "historical_dir": str(hist.output_dir),
        "byte_identical_pages": identical,
        "page_count": SOURCE_PAGE_COUNT,
        "fresh_decision": fresh_metrics.get("decision"),
        "historical_decision": hist_metrics.get("decision"),
        "fresh_catalog_fingerprint": catalog_fingerprint(fresh_digests)
        if len(fresh_digests) == SOURCE_PAGE_COUNT
        else None,
        "historical_catalog_fingerprint": catalog_fingerprint(hist_digests)
        if len(hist_digests) == SOURCE_PAGE_COUNT
        else CATALOG_FINGERPRINT,
        "classifications": {
            key: sum(1 for page in pages if page["classification"] == key)
            for key in (
                "byte_identical",
                "structurally_equivalent_byte_different",
                "structurally_equivalent_pixels_differ",
                "unexpected_difference",
            )
        },
        "pages": pages,
        "page16": next((page for page in pages if page["page"] == 16), None),
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--fresh-dir", type=Path, required=True)
    parser.add_argument("--historical-dir", type=Path, default=OUTPUT_DIR)
    parser.add_argument("--json", type=Path)
    args = parser.parse_args(argv)
    report = compare(args.fresh_dir, args.historical_dir)
    text = json.dumps(report, indent=2)
    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(text, encoding="utf-8")
    print(text)
    return 0


if __name__ == "__main__":
    sys.exit(main())
