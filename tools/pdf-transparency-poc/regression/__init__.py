"""Mantirigam reference-PDF regression harness.

Validates the exact 33-page source fixture and the historical Phase 2
outputs. Processing, package generation and activation stay separate.
"""

from .result import ReferenceRegressionResult

__all__ = [
    "ReferenceRegressionResult",
    "run_reference_regression",
]


def run_reference_regression(*args, **kwargs):
    from .run_harness import run_reference_regression as _run

    return _run(*args, **kwargs)
