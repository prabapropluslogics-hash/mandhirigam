"""Canonical Mantirigam reference-PDF fixture constants.

These values come from the verified source PDF and the Phase 2 historical
run. Do not invent new grid geometries.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

POC_ROOT = Path(__file__).resolve().parents[1]
REPO_ROOT = POC_ROOT.parents[1]

SOURCE_PDF = POC_ROOT / "input" / "original.pdf"
OUTPUT_DIR = POC_ROOT / "output" / "phase2_all_33"
METRICS_JSON = OUTPUT_DIR / "metrics.json"
REPORT_MD = POC_ROOT / "reports" / "phase2_all_33_report.md"
PACKAGE_MANIFEST = POC_ROOT / "reports" / "phase2_png_reader_manifest.json"
PROCESSOR_SCRIPT = POC_ROOT / "scripts" / "08_phase2_all_33.py"

SOURCE_SHA256 = (
    "d9d6ebfaea32e221e9a4465980e4cd7feaee8a45dd186d3e8001eb1199d95231"
)
SOURCE_BYTES = 5_380_261
SOURCE_PAGE_COUNT = 33
SOURCE_PAGE_WIDTH_PT = 595.32
SOURCE_PAGE_HEIGHT_PT = 841.92

OUTPUT_WIDTH = 1241
OUTPUT_HEIGHT = 1754
CATALOG_FINGERPRINT = (
    "d60972fe641e5bd598ba1dde0d2e1e740d76819c22338450835bb4af2e9d11f2"
)
TRANSPARENT_PDF_SHA256 = (
    "a8c45cd37d0de044a47d02820eb365c881758ac4a91621fa663dfb291a62d86f"
)

EXPECTED_PASS = 32
EXPECTED_NEEDS_REVIEW = 1
EXPECTED_FAIL = 0
EXPECTED_DECISION = "CONDITIONAL GO"


@dataclass(frozen=True)
class PageExpectation:
    page: int
    status: str
    segmented_grids: tuple[str, ...]
    require_opaque_fallback: bool = False
    min_segmented_diagrams: int = 1
    min_ink_blocks: int = 0
    note_contains: tuple[str, ...] = ()


# Mandatory regression pages. Grids are historical Phase 2 results only.
PAGE_EXPECTATIONS: dict[int, PageExpectation] = {
    1: PageExpectation(
        page=1,
        status="PASS",
        segmented_grids=("3x3", "5x3"),
        min_segmented_diagrams=2,
        min_ink_blocks=1,
    ),
    7: PageExpectation(
        page=7,
        status="PASS",
        segmented_grids=("9x9",),
        min_segmented_diagrams=1,
    ),
    11: PageExpectation(
        page=11,
        status="PASS",
        segmented_grids=("4x3", "7x4"),
        min_segmented_diagrams=2,
        min_ink_blocks=1,
    ),
    16: PageExpectation(
        page=16,
        status="NEEDS_REVIEW",
        segmented_grids=("4x4",),
        require_opaque_fallback=True,
        min_segmented_diagrams=1,
        note_contains=("kept opaque", "not regular"),
    ),
    23: PageExpectation(
        page=23,
        status="PASS",
        segmented_grids=("4x4", "4x4"),
        min_segmented_diagrams=2,
        min_ink_blocks=1,
    ),
    25: PageExpectation(
        page=25,
        status="PASS",
        segmented_grids=("3x4", "4x5", "4x4"),
        min_segmented_diagrams=3,
        min_ink_blocks=1,
    ),
    33: PageExpectation(
        page=33,
        status="PASS",
        segmented_grids=("4x4", "7x4"),
        min_segmented_diagrams=2,
        min_ink_blocks=1,
    ),
}


def page_dir(page: int) -> Path:
    return OUTPUT_DIR / f"page_{page:02d}"


def packed_png(page: int) -> Path:
    return page_dir(page) / "packed.png"


def original_png(page: int) -> Path:
    return page_dir(page) / "original.png"
