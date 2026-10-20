# Changelog

## 0.3.1 — 2026-10-20

- Add a complete, executable Chinese README and reciprocal documentation links.
- Accept bounded non-endpoint depth grids when the actual sample count fits the limit; retain rejection of genuinely oversized grids.
- Preserve finite values exactly when converting equivalent unit aliases, avoiding unnecessary base-unit overflow or precision loss. Cover direct conversion, owned curve snapshots, and multi-run provenance with regression tests.

## 0.3.0 — 2026-10-16

- Add immutable source-document archival, ordered duplicate entries and structured standard/resource diagnostics, explicitly separate from finite-Double numerical-model errors.
- Implement the declared CWLS January-2014 strict baseline: complete well headers and regional identifiers, encoding/CRLF, sections, index/time rules, exact decimal endpoints/intervals/divisibility and WRAP physical widths.
- Add strict parse/conversion/write APIs and validate/archive/strict-normalize protocol commands; retain compatibility APIs without conformance claims.
- Expand output exponents to exact roundtrip decimals and compute STEP from serialized coordinates; reject underflow and false NULL collapse rather than silently changing meaning.
- Add 105 deterministic conformance cases, independent Python structure/Decimal validation, public strict workflows and CI integration with existing lasio oracles.
- Replace the former known-gap roadmap with implemented rule/evidence mappings. No latest-edition, CWLS certification or organizer-acceptance claim.

## 0.2.0 — 2026-10-16

- Breaking: add `Curve.api_code`; use an empty string for absent codes. Preserve opaque codes through reader/writer and transforms; assembly fills missing definitions and rejects contradictory nonempty codes.
- Use the last colon delimiter, permit colons in data and printable mnemonic punctuation. Colon-bearing descriptions require explicit migration.
- Preserve customer sections and extra version headers in owned snapshots; require Version first.
- Emit CRLF and split wrapped sample lines to the 80-character limit including terminators.
- Add public executable cases, independent metadata oracle and a standards matrix with an explicit, still-open complete-conformance gate.

## 0.1.0 — 2026-10-14

- Initial strict LAS2 metadata/ASCII parser and canonical writer.
- Validated depth-indexed optional numerical table with dimensional conversions.
- Gap-aware resampling, missing-span fill, moments/quantiles, QC, interval integrals and explicit curve transforms.
- Unit-aligned multi-run assembly with conflict policies and per-cell source provenance.
- Structured reports, numerical/provenance CSV and MoonBit JSON workflow dispatch.
- IO-only Node adapter, three portable downstream workflows, boundary regression tests, optional independent lasio oracle and four-target CI.

Known boundaries: strict subset, no LAS3/DLIS/LIS/proprietary dialects, no reservoir/drilling interpretation, no automatic depth shift or alias guessing. The initial Windows machine lacks a system native C compiler; CI handles native execution.
