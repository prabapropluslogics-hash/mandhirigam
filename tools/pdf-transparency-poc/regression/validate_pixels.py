"""Decoded RGBA pixel comparison between fresh and historical packed PNGs.

PNG byte hashes may differ across encoder versions. Visual content is judged
by full RGBA array equality after decode — never by compressed file bytes.
"""

from __future__ import annotations

import numpy as np
from PIL import Image

from .fixture import SOURCE_PAGE_COUNT
from .paths import HarnessPaths
from .result import CheckResult, ReferenceRegressionResult
from .validate_source import sha256_file

BYTE_IDENTICAL = "BYTE_IDENTICAL"
PIXEL_IDENTICAL_BYTE_DIFFERENT = "PIXEL_IDENTICAL_BYTE_DIFFERENT"
PIXEL_DIFFERENT = "PIXEL_DIFFERENT"


def _compare_page(fresh_path, baseline_path) -> dict:
    fresh_sha = sha256_file(fresh_path)
    hist_sha = sha256_file(baseline_path)
    fresh = np.asarray(Image.open(fresh_path).convert("RGBA"), dtype=np.uint8)
    hist = np.asarray(Image.open(baseline_path).convert("RGBA"), dtype=np.uint8)

    report: dict = {
        "page": None,
        "classification": PIXEL_DIFFERENT,
        "fresh_sha256": fresh_sha,
        "historical_sha256": hist_sha,
        "fresh_bytes": fresh_path.stat().st_size,
        "historical_bytes": baseline_path.stat().st_size,
        "shape_fresh": list(fresh.shape),
        "shape_historical": list(hist.shape),
        "changed_pixel_count": 0,
        "max_channel_diff": 0,
    }

    if fresh_sha == hist_sha:
        report["classification"] = BYTE_IDENTICAL
        return report

    if fresh.shape != hist.shape:
        report["classification"] = PIXEL_DIFFERENT
        report["changed_pixel_count"] = int(np.prod(fresh.shape[:2]))
        report["max_channel_diff"] = 255
        return report

    diff = np.abs(fresh.astype(np.int16) - hist.astype(np.int16))
    pixel_changed = np.any(diff != 0, axis=2)
    changed = int(pixel_changed.sum())
    max_diff = int(diff.max()) if diff.size else 0
    report["changed_pixel_count"] = changed
    report["max_channel_diff"] = max_diff

    if changed == 0:
        report["classification"] = PIXEL_IDENTICAL_BYTE_DIFFERENT
    else:
        report["classification"] = PIXEL_DIFFERENT
    return report


def validate_pixel_parity(
    result: ReferenceRegressionResult,
    paths: HarnessPaths,
) -> None:
    """Fresh mode only: compare decoded RGBA against the historical baseline."""
    if not paths.is_fresh:
        return
    if paths.baseline_output_dir is None or not paths.baseline_output_dir.is_dir():
        result.add(
            CheckResult(
                "pixel_baseline_available",
                False,
                detail=str(paths.baseline_output_dir),
            )
        )
        return

    result.add(
        CheckResult(
            "pixel_baseline_available",
            True,
            detail=str(paths.baseline_output_dir),
        )
    )

    classifications: dict[str, int] = {
        BYTE_IDENTICAL: 0,
        PIXEL_IDENTICAL_BYTE_DIFFERENT: 0,
        PIXEL_DIFFERENT: 0,
    }

    for page in range(1, SOURCE_PAGE_COUNT + 1):
        fresh_path = paths.packed_png(page)
        baseline_path = paths.baseline_packed_png(page)
        if baseline_path is None or not fresh_path.is_file() or not baseline_path.is_file():
            entry = {
                "page": page,
                "classification": PIXEL_DIFFERENT,
                "changed_pixel_count": -1,
                "max_channel_diff": -1,
                "detail": "missing fresh or baseline packed.png",
            }
            result.pixel_comparisons.append(entry)
            classifications[PIXEL_DIFFERENT] += 1
            result.add(
                CheckResult(
                    f"page_{page:02d}_pixel_parity",
                    False,
                    detail="missing packed.png for pixel comparison",
                )
            )
            continue

        entry = _compare_page(fresh_path, baseline_path)
        entry["page"] = page
        result.pixel_comparisons.append(entry)
        classifications[entry["classification"]] += 1

        ok = entry["classification"] in {BYTE_IDENTICAL, PIXEL_IDENTICAL_BYTE_DIFFERENT}
        if ok:
            detail = (
                f"{entry['classification']} "
                f"fresh_sha={entry['fresh_sha256'][:12]}… "
                f"hist_sha={entry['historical_sha256'][:12]}…"
            )
        else:
            detail = (
                f"{PIXEL_DIFFERENT} changed_px={entry['changed_pixel_count']} "
                f"max_channel_diff={entry['max_channel_diff']}"
            )
        result.add(
            CheckResult(
                f"page_{page:02d}_pixel_parity",
                ok,
                detail=detail,
            )
        )

    result.pixel_classification_counts = classifications
    all_pixel_ok = classifications[PIXEL_DIFFERENT] == 0
    result.add(
        CheckResult(
            "all_pages_pixel_identical_or_better",
            all_pixel_ok,
            detail=str(classifications),
        )
    )
    # Different PNG bytes alone are not a visual failure.
    result.add(
        CheckResult(
            "png_byte_hash_not_visual_gate",
            True,
            detail=(
                "PIXEL_IDENTICAL_BYTE_DIFFERENT is accepted; only decoded "
                "RGBA differences fail the fresh harness"
            ),
        )
    )
