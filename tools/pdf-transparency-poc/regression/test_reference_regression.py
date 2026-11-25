"""unittest entry for the Mantirigam reference-PDF regression harness."""

from __future__ import annotations

import unittest

from .fixture import (
    CATALOG_FINGERPRINT,
    EXPECTED_FAIL,
    EXPECTED_NEEDS_REVIEW,
    EXPECTED_PASS,
    SOURCE_SHA256,
)
from .run_harness import run_reference_regression


class ReferencePdfRegressionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.result = run_reference_regression(execute_processor=False)

    def test_harness_passes_historical_outputs(self) -> None:
        failures = [
            f"{check.name}: {check.detail}" for check in self.result.failures()
        ]
        self.assertTrue(
            self.result.ok,
            msg="reference regression failed:\n" + "\n".join(failures),
        )

    def test_processor_was_not_executed(self) -> None:
        self.assertFalse(self.result.processor_executed)

    def test_source_checksum(self) -> None:
        self.assertEqual(self.result.source_sha256, SOURCE_SHA256)

    def test_catalog_fingerprint(self) -> None:
        self.assertEqual(self.result.catalog_fingerprint, CATALOG_FINGERPRINT)

    def test_historical_status_counts(self) -> None:
        self.assertEqual(self.result.page_status_counts.get("PASS"), EXPECTED_PASS)
        self.assertEqual(
            self.result.page_status_counts.get("NEEDS_REVIEW"),
            EXPECTED_NEEDS_REVIEW,
        )
        self.assertEqual(self.result.page_status_counts.get("FAIL"), EXPECTED_FAIL)

    def test_page_16_needs_review_is_reported(self) -> None:
        names = {check.name for check in self.result.checks if check.ok}
        self.assertIn("page_16_status", names)
        self.assertIn("needs_review_is_page_16_only", names)
        self.assertIn("page_16_upper_kept_opaque", names)
        self.assertIn("page_16_lower_segmented_transparency", names)


if __name__ == "__main__":
    unittest.main()
