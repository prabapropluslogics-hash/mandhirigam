"""Shared result types for the reference regression harness."""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class CheckResult:
    name: str
    ok: bool
    detail: str = ""
    limitation: str = ""

    def as_dict(self) -> dict:
        return {
            "name": self.name,
            "ok": self.ok,
            "detail": self.detail,
            "limitation": self.limitation,
        }


@dataclass
class ReferenceRegressionResult:
    ok: bool
    processor_executed: bool = False
    mode: str = "historical"
    checks: list[CheckResult] = field(default_factory=list)
    page_status_counts: dict[str, int] = field(default_factory=dict)
    source_sha256: str = ""
    catalog_fingerprint: str = ""
    total_output_bytes: int = 0
    page_sha256s: dict[int, str] = field(default_factory=dict)
    pixel_comparisons: list[dict] = field(default_factory=list)
    pixel_classification_counts: dict[str, int] = field(default_factory=dict)
    document_decision: str = ""
    limitations: list[str] = field(default_factory=list)

    def add(self, check: CheckResult) -> None:
        # Coerce numpy.bool_ and similar into plain bool for JSON/CLI output.
        check.ok = bool(check.ok)
        self.checks.append(check)
        if check.limitation:
            self.limitations.append(check.limitation)
        if not check.ok:
            self.ok = False

    def failures(self) -> list[CheckResult]:
        return [check for check in self.checks if not check.ok]

    def as_dict(self) -> dict:
        return {
            "ok": self.ok,
            "mode": self.mode,
            "processor_executed": self.processor_executed,
            "document_decision": self.document_decision,
            "source_sha256": self.source_sha256,
            "catalog_fingerprint": self.catalog_fingerprint,
            "total_output_bytes": self.total_output_bytes,
            "page_sha256s": {
                str(page): digest for page, digest in sorted(self.page_sha256s.items())
            },
            "page_status_counts": self.page_status_counts,
            "pixel_classification_counts": self.pixel_classification_counts,
            "pixel_comparisons": self.pixel_comparisons,
            "limitations": self.limitations,
            "failures": [check.as_dict() for check in self.failures()],
            "checks": [check.as_dict() for check in self.checks],
        }
