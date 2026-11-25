"""Path bundle for the reference regression harness."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from .fixture import (
    METRICS_JSON,
    OUTPUT_DIR,
    PACKAGE_MANIFEST,
    SOURCE_PDF,
)

MODE_HISTORICAL = "historical"
MODE_FRESH = "fresh"


@dataclass(frozen=True)
class HarnessPaths:
    source_pdf: Path = SOURCE_PDF
    output_dir: Path = OUTPUT_DIR
    metrics_json: Path = METRICS_JSON
    package_manifest: Path | None = PACKAGE_MANIFEST
    # Historical mode only: expected page SHA/bytes come from this manifest.
    historical_manifest: Path | None = PACKAGE_MANIFEST
    # Fresh mode: decode-and-compare against this baseline (historical OUT).
    baseline_output_dir: Path | None = None
    mode: str = MODE_HISTORICAL

    @property
    def is_fresh(self) -> bool:
        return self.mode == MODE_FRESH

    def packed_png(self, page: int) -> Path:
        return self.output_dir / f"page_{page:02d}" / "packed.png"

    def original_png(self, page: int) -> Path:
        return self.output_dir / f"page_{page:02d}" / "original.png"

    def baseline_packed_png(self, page: int) -> Path | None:
        if self.baseline_output_dir is None:
            return None
        return self.baseline_output_dir / f"page_{page:02d}" / "packed.png"

    @classmethod
    def historical(cls) -> "HarnessPaths":
        return cls(mode=MODE_HISTORICAL)

    @classmethod
    def for_output_dir(cls, output_dir: Path) -> "HarnessPaths":
        """Fresh processor validation against an isolated output directory."""
        output_dir = output_dir.resolve()
        return cls(
            source_pdf=SOURCE_PDF,
            output_dir=output_dir,
            metrics_json=output_dir / "metrics.json",
            # Fresh catalog is written/verified from actual packed.png bytes.
            package_manifest=output_dir / "fresh_catalog_manifest.json",
            historical_manifest=None,
            baseline_output_dir=OUTPUT_DIR,
            mode=MODE_FRESH,
        )
