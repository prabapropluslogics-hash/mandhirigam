# Mantirigam reference PDF regression harness

Validates the exact 33-page Mantirigam Tamil spiritual-book PDF and the
historical Phase 2 transparent-page outputs.

## Fixture

- Source: `tools/pdf-transparency-poc/input/original.pdf`
- SHA-256: `d9d6ebfaea32e221e9a4465980e4cd7feaee8a45dd186d3e8001eb1199d95231`
- Historical outputs: `tools/pdf-transparency-poc/output/phase2_all_33/`
- Historical metrics: `output/phase2_all_33/metrics.json`

## Separation of concerns

| Concern | This harness |
| --- | --- |
| PDF processing | Not executed. Future backend processors can write the same output layout and reuse these validators. |
| Page validation | `validate_pages.py`, `validate_visual.py` |
| Package generation | Not executed. `validate_package.py` checks packed PNG pages and catalog metadata only. |
| Package activation | Out of scope. |

## Commands

From the Flutter repository root:

```bash
python3 -m tools.pdf-transparency-poc.regression.run_harness
```

If the package path with hyphens is awkward on your shell, run:

```bash
python3 -m unittest discover -s tools/pdf-transparency-poc/regression -p 'test_*.py'
```

or:

```bash
cd tools/pdf-transparency-poc
python3 -m regression.run_harness
python3 -m unittest regression.test_reference_regression
```

## Expected historical outcome

- 32 PASS
- 1 NEEDS_REVIEW (page 16)
- 0 FAIL

Passing this harness does **not** mean the automatic processor is
production-ready for arbitrary client PDFs. It means the exact reference
fixture and its historical outputs still satisfy the acceptance gates.
