# MoonWell

A pure MoonBit library for **LAS 2.0 well-log integrity and provenance-preserving multi-run assembly**. MIT licensed, module `2200732518gjy/moonwell` at 0.1.0.

MoonWell serves acquisition QA, research preprocessing, and archival integration. Its central workflow is not just a LAS converter: independent runs are converted to explicit target units, aligned onto a bounded depth grid, and resolved under an explicit conflict policy with **per-cell source indexes and interpolation flags**.

## Install and import


two-step consumer setup:

~~~sh
moon new consumer
cd consumer
moon add 2200732518gjy/moonwell@0.1.0
~~~

Add to the consumer package manifest:

~~~moonbit
import { "2200732518gjy/moonwell" @well }
~~~

Example inside a raising function or try/catch:

~~~moonbit
let log = @well.make_log(
  [{name:"DEPT",unit:"M",description:"depth"},
   {name:"GR",unit:"GAPI",description:"gamma ray"}],
  [[Some(0.0),Some(10.0)], [Some(2.0),Some(30.0)]],
)
let table = @well.resample(log, @well.depth_grid(0.0,2.0,0.5), 2.0)
let assembled = @well.assemble([log,table], ["original","resampled"],
  [0.0,1.0,2.0], 2.0, Reject)
let report = @well.assembly_report(assembled)
~~~

The complete executable in [examples/main.mbt](examples/main.mbt) exercises three input→processing→output workflows using public interfaces only. [pkg.generated.mbti](pkg.generated.mbti) is the generated public API.

## Capabilities

- Strict finite decimal grammar, bounded LAS section state machine, required VERS/WRAP/STRT/STOP/STEP/NULL metadata, rectangular ASCII records, wrapped and unwrapped decoding, sentinel→optional samples.
- Snapshot-owned rectangular tables with non-null, unique, monotonic depth in either direction; case-insensitive curve mnemonics; ascending/window/select transforms.
- Canonical LAS writer recomputes grid headers and refuses sentinel collisions; numerical CSV has quoted headers and blank missing cells.
- Binary-search adjacent-endpoint interpolation, explicit maximum gap, no extrapolation or null-endpoint bridging; bounded grids and missing-span fill.
- Explicit dimensional conversions: length, voltage, density, temperature and slowness. Unknown units may pass identically, never guessed.
- Null-aware moments and type-7 quantiles; clipped trapezoidal interval integrals with explicit coverage; deterministic range, gradient, constant-run, missing and depth-gap findings.
- Gap-stopping median filter, gradients, masks, affine transforms and validated derived curves.
- Multi-run union of curve names, unit-aware depth alignment, reject/first/last conflict policies, absolute tolerance, complete cell lineage and conflict reports.
- Versioned JSON QA/interval/assembly reports and a strict JSON command protocol implemented in MoonBit.

## IO-only Node CLI

Node 24 is used for file IO only; it does not parse LAS, compute statistics or decide conflicts.

~~~sh
moon build --target js --release --deny-warn
node tools/moonwell.mjs fixtures/qa.json
node tools/moonwell.mjs fixtures/assemble.json result.json
node tools/test-cli.mjs
~~~

One JSON request file produces one envelope: `{"ok":true,"result":...}` or `{"ok":false,"error":"..."}`. Output files use exclusive creation and **never overwrite**. Exit 0: successful envelope; 1: domain error envelope; 2: adapter/IO failure. The adapter returns error messages, not stack traces.

Commands: `qa`, `normalize`, `csv`, `resample`, `interval`, `assemble`. See [docs/protocol.md](docs/protocol.md) for exact fields. The library, not the file adapter, is the published integration surface.

## Verify

~~~sh
moon info
moon fmt
moon fmt --check
moon check --target wasm-gc --deny-warn
moon test --target wasm-gc --deny-warn
moon build --target wasm-gc --release --deny-warn
moon run examples --target wasm-gc --deny-warn
python tools/audit.py
~~~

Repeat target checks/tests/build/examples with wasm, js and native. Native requires a system C compiler (gcc/clang). Local Windows evidence: 40/40 tests per wasm-gc, wasm and js, strict builds and examples, CLI acceptance, **32/32 synthetic numerical differential cases against lasio 0.32**. Local native strict check passed; execution requires the missing system C compiler, so the four-target Linux CI is the native execution gate. CI pins the official development compiler bundle `0.10.14+7d59c7ec9` (the archive uses the compiler version, not the standalone moon CLI version) and records its actual toolchain. No local native execution is claimed.

Optional independent oracle:

~~~sh
python -m pip install lasio==0.32 numpy==2.3.5
python tools/differential.py
~~~

Production implementation contains 2042 nonblank, noncomment MoonBit lines before any later repairs; tests, generated interfaces, examples and bridge excluded. `tools/audit.py` recomputes the count and commit threshold; nonempty commits are additionally reviewed for coherent engineering changes, not artificially split history.

## Scope and cautions

This is a **declared strict LAS2 subset**, not universal LAS conformance. Mnemonics use ASCII letters/digits/underscore/hyphen. Unknown sections, duplicate metadata, curve-line values, arbitrary delimiters, comma decimals, LAS3, DLIS/LIS and vendor dialects are unsupported. Wrapped multi-column records must start with a depth-only line. Nonzero STEP must agree with each actual interval; zero STEP permits irregular depth. Canonical writing does not preserve comments/spacing/version extensions. Empty tables are valid in memory but cannot be written to LAS.

No curve alias inference, depth-shift optimization, reservoir interpretation, drilling advice, safety decisions, geological inference or thermodynamic model is provided. QA thresholds and units remain the caller's responsibility. Equal-within-tolerance observations retain the earlier source even under PreferLast. Conflict records identify the previous/incoming observations before policy application. Generated depth cells deliberately have no run owner.

Arrays are readable and mutable; constructors snapshot inputs, transformations rebuild validated copies, and report writers revalidate their input. Do not mutate objects concurrently. Use numerical CSV in data pipelines, not as a safe spreadsheet-formula format for untrusted run names.

See [architecture](docs/architecture.md), [security](SECURITY.md), [references and AI disclosure](SOURCE_ATTRIBUTION.md), [bounded duplication review](docs/competition/duplicate-check.md), and [changelog](CHANGELOG.md). Application/registration materials are deliberately absent from the source package.
