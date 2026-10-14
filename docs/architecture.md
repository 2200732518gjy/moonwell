# Architecture and invariants

## Layers

1. lex/header/parse: strict tokenization, metadata state machine, record decoding and endpoint/STEP integrity.
2. model/depth/units: owned validated tables, case-insensitive identities and explicit physical dimensions.
3. resample/missing/stats/interval/qc/filter/transform: bounded algorithms with caller-selected thresholds.
4. assembly: named runs, target units, curve union, policy decisions, per-cell lineage, pre-policy conflict evidence.
5. writer/csv/report: explicit numeric serialization and versioned structured reports.
6. protocol: strict command fields and one response envelope. cmd/bridge and tools/moonwell.mjs are JS-only IO glue; core has no FFI or IO.

## Numerical policy

- Only finite values, with None for missing observations. NULL is a file representation, never a numerical sample.
- Strict unique monotonic depth, accepting ascending/descending acquisition order. Public interpolation normalizes to ascending snapshots.
- An exact depth uses its existing sample, even next to a large gap. Interior points need adjacent valid endpoints within max_gap. No extrapolation.
- Fill uses original bracketing endpoints, never extends edges. Median filtering stops at nulls/depth gaps and uses original values, not earlier filtered output.
- Interval integrals clip linear segments to requested boundaries; coverage denominator is the requested interval, not observed extent. Missing coverage is never reported as zero-valued data.
- Moments scale finite observations before Welford accumulation. Population variance, not sample variance. Overflow is an error; no NaN/Infinity in reports.
- Assembly first establishes target metadata from the first appearance of each curve; depth uses the first run's unit. Incoming values convert dimensionally before interpolation. Absolute conflict tolerance is in output curve units, not a percentage.
- PreferFirst/PreferLast apply only to differences above tolerance; identical observations retain first lineage. Reject raises, without returning a partial table.

## Budgets

Text 16 million code units; input CLI file 16 MB; JSON nesting 32; 512 curves; 1 million rows; 10 million model/resample cells; default grid 100,000 samples and configurable maximum 1 million; 64 runs; assembly 20 million output-cell/run work units; filter radius 1..1000 and 20 million neighbor work units; 512 QC rules and 1 million curve findings.

Bounds are not a sandbox or a universal memory/time guarantee. Validation and metadata uniqueness have quadratic curve/header comparisons. Each API validates exposed mutable arrays; consumers should not mutate during a call. Domain-specific implicit curve aliases and logarithmic interpolation are intentionally excluded.
