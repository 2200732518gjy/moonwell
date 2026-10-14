# Changelog

## 0.1.0 — 2026-10-14

- Initial strict LAS2 metadata/ASCII parser and canonical writer.
- Validated depth-indexed optional numerical table with dimensional conversions.
- Gap-aware resampling, missing-span fill, moments/quantiles, QC, interval integrals and explicit curve transforms.
- Unit-aligned multi-run assembly with conflict policies and per-cell source provenance.
- Structured reports, numerical/provenance CSV and MoonBit JSON workflow dispatch.
- IO-only Node adapter, three portable downstream workflows, boundary regression tests, optional independent lasio oracle and four-target CI.

Known boundaries: strict subset, no LAS3/DLIS/LIS/proprietary dialects, no reservoir/drilling interpretation, no automatic depth shift or alias guessing. The initial Windows machine lacks a system native C compiler; CI handles native execution.
