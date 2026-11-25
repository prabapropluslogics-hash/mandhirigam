"""Source-PDF validation. Does not modify the PDF."""

from __future__ import annotations

import hashlib
from pathlib import Path

from pypdf import PdfReader

from .fixture import (
    SOURCE_BYTES,
    SOURCE_PAGE_COUNT,
    SOURCE_PAGE_HEIGHT_PT,
    SOURCE_PAGE_WIDTH_PT,
    SOURCE_SHA256,
)
from .paths import HarnessPaths
from .result import CheckResult, ReferenceRegressionResult


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while True:
            chunk = handle.read(1024 * 1024)
            if not chunk:
                break
            digest.update(chunk)
    return digest.hexdigest()


def validate_source(
    result: ReferenceRegressionResult,
    paths: HarnessPaths | None = None,
) -> None:
    paths = paths or HarnessPaths.historical()
    source = paths.source_pdf
    result.add(
        CheckResult(
            "source_exists",
            source.is_file(),
            detail=str(source),
        )
    )
    if not source.is_file():
        return

    size = source.stat().st_size
    result.add(
        CheckResult(
            "source_byte_size",
            size == SOURCE_BYTES,
            detail=f"size={size} expected={SOURCE_BYTES}",
        )
    )

    digest = sha256_file(source)
    result.source_sha256 = digest
    result.add(
        CheckResult(
            "source_sha256",
            digest == SOURCE_SHA256,
            detail=digest,
        )
    )

    reader = PdfReader(str(source))
    page_count = len(reader.pages)
    result.add(
        CheckResult(
            "source_page_count",
            page_count == SOURCE_PAGE_COUNT,
            detail=f"pages={page_count}",
        )
    )
    if page_count == 0:
        return

    box = reader.pages[0].mediabox
    width = round(float(box.width), 2)
    height = round(float(box.height), 2)
    result.add(
        CheckResult(
            "source_page_geometry",
            width == SOURCE_PAGE_WIDTH_PT and height == SOURCE_PAGE_HEIGHT_PT,
            detail=f"{width}x{height}",
        )
    )

    mismatched = []
    for index, page in enumerate(reader.pages, start=1):
        page_box = page.mediabox
        page_w = round(float(page_box.width), 2)
        page_h = round(float(page_box.height), 2)
        if page_w != SOURCE_PAGE_WIDTH_PT or page_h != SOURCE_PAGE_HEIGHT_PT:
            mismatched.append(index)
    result.add(
        CheckResult(
            "source_all_pages_a4",
            not mismatched,
            detail="ok" if not mismatched else f"mismatched={mismatched}",
        )
    )
