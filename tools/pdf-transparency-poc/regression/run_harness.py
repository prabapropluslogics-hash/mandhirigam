"""Orchestrates the Mantirigam reference-PDF regression suite.

Two modes:
- historical (default): bit-for-bit integrity of frozen Phase 2 artifacts
- fresh (--output-dir): structural + decoded RGBA parity vs historical baseline

PDF processing is executed separately. Package activation is out of scope.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from .fixture import EXPECTED_DECISION, PROCESSOR_SCRIPT
from .paths import HarnessPaths
from .result import CheckResult, ReferenceRegressionResult
from .validate_package import validate_package
from .validate_pages import validate_page_metadata
from .validate_pixels import validate_pixel_parity
from .validate_source import validate_source
from .validate_visual import validate_visual


def run_reference_regression(
    *,
    execute_processor: bool = False,
    paths: HarnessPaths | None = None,
) -> ReferenceRegressionResult:
    """Validate the reference fixture against historical or fresh outputs."""
    paths = paths or HarnessPaths.historical()
    result = ReferenceRegressionResult(
        ok=True,
        processor_executed=False,
        mode=paths.mode,
    )

    result.add(
        CheckResult(
            "processor_script_present",
            PROCESSOR_SCRIPT.is_file(),
            detail=str(PROCESSOR_SCRIPT),
        )
    )
    result.add(
        CheckResult(
            "harness_output_dir",
            True,
            detail=str(paths.output_dir),
        )
    )

    if execute_processor:
        result.add(
            CheckResult(
                "processor_execution",
                False,
                detail=(
                    "execute_processor=True is reserved for an in-process runner. "
                    "Execute scripts/08_phase2_all_33.py separately, then pass "
                    "--output-dir to this harness."
                ),
            )
        )
        return result

    validate_source(result, paths)
    validate_package(result, paths)
    metrics = validate_page_metadata(result, paths)
    if metrics:
        result.document_decision = str(metrics.get("decision") or "")
        validate_visual(result, metrics, paths)
        if paths.is_fresh:
            validate_pixel_parity(result, paths)
            # A successful fresh structural+pixel run is not production READY.
            result.add(
                CheckResult(
                    "document_decision_remains_conditional_go",
                    result.document_decision == EXPECTED_DECISION,
                    detail=(
                        f"document_decision={result.document_decision!r}; "
                        "fresh validation success does not promote to READY"
                    ),
                )
            )
    return result


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Run the Mantirigam 33-page reference PDF regression harness "
            "against historical artifacts or freshly generated Phase 2 outputs."
        )
    )
    parser.add_argument(
        "--json",
        type=Path,
        help="Optional path to write the full machine-readable result JSON.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        help=(
            "Fresh Phase 2 output directory. Enables pixel-parity mode that "
            "does not gate on historical PNG byte hashes. Defaults to the "
            "historical tools/.../output/phase2_all_33 integrity mode."
        ),
    )
    parser.add_argument(
        "--execute-processor",
        action="store_true",
        help="Rejected here; run scripts/08_phase2_all_33.py separately.",
    )
    args = parser.parse_args(argv)

    paths = (
        HarnessPaths.for_output_dir(args.output_dir)
        if args.output_dir is not None
        else HarnessPaths.historical()
    )
    result = run_reference_regression(
        execute_processor=args.execute_processor,
        paths=paths,
    )
    payload = result.as_dict()
    if args.json is not None:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(payload, indent=2), encoding="utf-8")

    failures = result.failures()
    print(
        f"reference_regression ok={result.ok} mode={result.mode} "
        f"checks={len(result.checks)} failures={len(failures)} "
        f"processor_executed={result.processor_executed}"
    )
    print(f"output_dir={paths.output_dir}")
    print(
        "status_counts "
        f"PASS={result.page_status_counts.get('PASS')} "
        f"NEEDS_REVIEW={result.page_status_counts.get('NEEDS_REVIEW')} "
        f"FAIL={result.page_status_counts.get('FAIL')}"
    )
    print(f"source_sha256={result.source_sha256}")
    print(f"catalog_fingerprint={result.catalog_fingerprint}")
    if result.total_output_bytes:
        print(f"total_output_bytes={result.total_output_bytes}")
    if result.document_decision:
        print(f"document_decision={result.document_decision}")
    if result.pixel_classification_counts:
        print(f"pixel_classifications={result.pixel_classification_counts}")
    if result.limitations:
        print("limitations:")
        for item in sorted(set(result.limitations)):
            print(f"- {item}")
    if failures:
        print("failures:")
        for check in failures:
            print(f"- {check.name}: {check.detail}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
