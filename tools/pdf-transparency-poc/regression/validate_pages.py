"""Page-specific historical metadata regression checks."""

from __future__ import annotations

import json
from collections import Counter
from typing import Any

from .fixture import (
    EXPECTED_DECISION,
    EXPECTED_FAIL,
    EXPECTED_NEEDS_REVIEW,
    EXPECTED_PASS,
    PAGE_EXPECTATIONS,
    REPORT_MD,
    SOURCE_PAGE_COUNT,
)
from .paths import HarnessPaths
from .result import CheckResult, ReferenceRegressionResult


def _segmented_grids(page: dict[str, Any]) -> list[str]:
    return [
        str(image.get("grid_class"))
        for image in page.get("embedded_images") or []
        if image.get("mode") == "segmented"
    ]


def _modes(page: dict[str, Any]) -> Counter:
    return Counter(
        str(image.get("mode"))
        for image in page.get("embedded_images") or []
    )


def validate_page_metadata(
    result: ReferenceRegressionResult,
    paths: HarnessPaths | None = None,
) -> dict[str, Any]:
    paths = paths or HarnessPaths.historical()
    metrics_json = paths.metrics_json
    report_md = paths.output_dir / "phase2_all_33_report.md"
    if not report_md.is_file():
        report_md = REPORT_MD
    result.add(
        CheckResult(
            "metrics_json_exists",
            metrics_json.is_file(),
            detail=str(metrics_json),
        )
    )
    result.add(
        CheckResult(
            "report_md_exists",
            report_md.is_file(),
            detail=str(report_md),
        )
    )
    if not metrics_json.is_file():
        return {}

    metrics = json.loads(metrics_json.read_text(encoding="utf-8"))
    pages = metrics.get("pages") or []
    result.add(
        CheckResult(
            "metrics_page_count",
            len(pages) == SOURCE_PAGE_COUNT,
            detail=str(len(pages)),
        )
    )

    counts = Counter(str(page.get("status")) for page in pages)
    result.page_status_counts = {
        "PASS": counts.get("PASS", 0),
        "NEEDS_REVIEW": counts.get("NEEDS_REVIEW", 0),
        "FAIL": counts.get("FAIL", 0),
    }
    result.add(
        CheckResult(
            "status_counts",
            counts.get("PASS", 0) == EXPECTED_PASS
            and counts.get("NEEDS_REVIEW", 0) == EXPECTED_NEEDS_REVIEW
            and counts.get("FAIL", 0) == EXPECTED_FAIL,
            detail=str(dict(result.page_status_counts)),
        )
    )
    result.add(
        CheckResult(
            "decision",
            metrics.get("decision") == EXPECTED_DECISION,
            detail=str(metrics.get("decision")),
        )
    )

    by_page = {int(page["original_page"]): page for page in pages}
    for page_no, expectation in PAGE_EXPECTATIONS.items():
        page = by_page.get(page_no)
        if page is None:
            result.add(
                CheckResult(
                    f"page_{page_no:02d}_metadata",
                    False,
                    detail="missing from metrics.json",
                )
            )
            continue

        result.add(
            CheckResult(
                f"page_{page_no:02d}_status",
                page.get("status") == expectation.status,
                detail=str(page.get("status")),
            )
        )

        grids = _segmented_grids(page)
        result.add(
            CheckResult(
                f"page_{page_no:02d}_grids",
                grids == list(expectation.segmented_grids),
                detail=",".join(grids) if grids else "(none)",
            )
        )

        modes = _modes(page)
        result.add(
            CheckResult(
                f"page_{page_no:02d}_segmented_count",
                modes.get("segmented", 0) >= expectation.min_segmented_diagrams,
                detail=str(dict(modes)),
            )
        )
        if expectation.min_ink_blocks:
            result.add(
                CheckResult(
                    f"page_{page_no:02d}_ink_present",
                    modes.get("ink_only", 0) >= expectation.min_ink_blocks,
                    detail=str(dict(modes)),
                )
            )
        if expectation.require_opaque_fallback:
            result.add(
                CheckResult(
                    f"page_{page_no:02d}_opaque_fallback",
                    modes.get("opaque_fallback", 0) >= 1,
                    detail=str(dict(modes)),
                )
            )

        notes = " ".join(str(item) for item in (page.get("notes") or []))
        for needle in expectation.note_contains:
            result.add(
                CheckResult(
                    f"page_{page_no:02d}_note_{needle.replace(' ', '_')}",
                    needle in notes,
                    detail=notes or "(no notes)",
                )
            )

        # Protected-content metrics from the historical processor.
        page_metrics = page.get("metrics_vs_original_on_paper") or {}
        result.add(
            CheckResult(
                f"page_{page_no:02d}_text_mae",
                float(page_metrics.get("text_region_mae") or 0) == 0.0,
                detail=str(page_metrics.get("text_region_mae")),
            )
        )
        result.add(
            CheckResult(
                f"page_{page_no:02d}_cell_mae",
                float(page_metrics.get("protected_cell_mae") or 0) == 0.0,
                detail=str(page_metrics.get("protected_cell_mae")),
            )
        )
        result.add(
            CheckResult(
                f"page_{page_no:02d}_cell_leaks",
                int(page.get("cell_alpha_zero_px") or 0) == 0,
                detail=str(page.get("cell_alpha_zero_px")),
            )
        )
        result.add(
            CheckResult(
                f"page_{page_no:02d}_fg_cleared",
                int(page.get("fg_alpha_zero_px") or 0) == 0,
                detail=str(page.get("fg_alpha_zero_px")),
            )
        )
        result.add(
            CheckResult(
                f"page_{page_no:02d}_opaque_rgb",
                int(page.get("opaque_rgb_max_delta") or 0) == 0,
                detail=str(page.get("opaque_rgb_max_delta")),
            )
        )

    # Page 7 geometry: 9x9 / 81 cells and ten boundaries on each axis.
    page7 = by_page.get(7)
    if page7 is not None:
        yantra = next(
            (
                image
                for image in page7.get("embedded_images") or []
                if image.get("grid_class") == "9x9"
                and image.get("mode") == "segmented"
            ),
            None,
        )
        result.add(
            CheckResult(
                "page_07_cells_81",
                bool(
                    yantra
                    and yantra.get("rows") == 9
                    and yantra.get("cols") == 9
                    and yantra.get("cells") == 81
                ),
                detail=str(
                    None
                    if yantra is None
                    else {
                        "rows": yantra.get("rows"),
                        "cols": yantra.get("cols"),
                        "cells": yantra.get("cells"),
                        "h_lines": yantra.get("h_lines"),
                        "v_lines": yantra.get("v_lines"),
                    }
                ),
            )
        )
        result.add(
            CheckResult(
                "page_07_boundary_lines",
                bool(
                    yantra
                    and int(yantra.get("h_lines") or 0) >= 10
                    and int(yantra.get("v_lines") or 0) >= 10
                ),
                detail=str(
                    None
                    if yantra is None
                    else {
                        "h_lines": yantra.get("h_lines"),
                        "v_lines": yantra.get("v_lines"),
                    }
                ),
            )
        )
        geometry = (metrics.get("regression") or {}).get("page7_geometry") or {}
        result.add(
            CheckResult(
                "page_07_regression_geometry",
                bool(geometry.get("pass"))
                and geometry.get("rows") == 9
                and geometry.get("cols") == 9
                and geometry.get("cells") == 81,
                detail=str(geometry),
            )
        )

    # Page 16 must remain the sole NEEDS_REVIEW page.
    review_pages = [
        int(page["original_page"])
        for page in pages
        if page.get("status") == "NEEDS_REVIEW"
    ]
    result.add(
        CheckResult(
            "needs_review_is_page_16_only",
            review_pages == [16],
            detail=str(review_pages),
        )
    )

    if report_md.is_file():
        report = report_md.read_text(encoding="utf-8")
        result.add(
            CheckResult(
                "report_mentions_page16_needs_review",
                "Page 16 **NEEDS_REVIEW**" in report
                or "| 16 | NEEDS_REVIEW |" in report,
                detail=str(report_md),
            )
        )

    return metrics
