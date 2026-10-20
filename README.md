# MoonWell

[English](README.md) | [简体中文](README.zh-CN.md)

A pure MoonBit library for **LAS 2.0 well-log integrity and provenance-preserving multi-run assembly**. MIT licensed, module `2200732518gjy/moonwell` at 0.3.1.

MoonWell serves acquisition QA, research preprocessing, and archival integration. Its central workflow is not just a LAS converter: independent runs are converted to explicit target units, aligned onto a bounded depth grid, and resolved under an explicit conflict policy with **per-cell source indexes and interpolation flags**.

## Install and import


two-step consumer setup:

~~~sh
moon new consumer
cd consumer
moon add 2200732518gjy/moonwell@0.3.1
~~~

Add to the consumer package manifest:

~~~moonbit
import { "2200732518gjy/moonwell" @well }
~~~

Example inside a raising function or try/catch:

~~~moonbit
let log = @well.make_log(
  [{name:"DEPT",unit:"M",api_code:"",description:"depth"},
   {name:"GR",unit:"GAPI",api_code:"45 310 01 00",description:"gamma ray"}],
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

Commands: `qa`, `normalize`, `csv`, `resample`, `interval`, `assemble`, `validate-las2`, `archive-las2`, `strict-normalize`. See [docs/protocol.md](docs/protocol.md) for exact fields. The library, not the file adapter, is the published integration surface.

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

Repeat target checks/tests/build/examples with wasm, js and native. Native requires a system C compiler (gcc/clang). Original v0.1.0 local Windows evidence: 40/40 tests per wasm-gc, wasm and js, strict builds and examples, CLI acceptance, **32/32 synthetic numerical differential cases against lasio 0.32**. Local native strict check passed; execution requires the missing system C compiler, so the four-target Linux CI is the native execution gate. CI pins the official development compiler bundle `0.10.14+7d59c7ec9` (the archive uses the compiler version, not the standalone moon CLI version) and records its actual toolchain. No local native execution is claimed.

Optional independent oracle:

~~~sh
python -m pip install lasio==0.32 numpy==2.3.5
python tools/differential.py
~~~

The original v0.1.0 production implementation contains 2042 nonblank, noncomment MoonBit lines before any later repairs; tests, generated interfaces, examples and bridge excluded. `tools/audit.py` recomputes the count and commit threshold; nonempty commits are additionally reviewed for coherent engineering changes, not artificially split history.

## Scope and cautions

LAS2 conformance is now an explicit path, frozen to **CWLS January 2014**, not a latest-edition or third-party certification claim. Use `read_las_document` + `check_las2` for structured standard/resource diagnostics and `document_text` for exact original text (including comments, duplicate names and layout). Use `parse_strict` / `document_to_log` for validated numerical conversion and `write_las_strict` for revalidated standard output. Legal documents that cannot fit the unique-column finite-Double model raise `model:` instead of being declared illegal or silently losing columns. Strict writing expands exponents, uses exact decimal grid checks, and never fabricates missing well metadata or rounds observations. See the [implemented rules, budgets, examples and conformance gate](docs/las2-conformance.md).

The original `parse` / `write_las` are **compatibility APIs**, not conformance assertions. Canonical writing is not an exact archive. Empty tables are valid in memory but cannot be written to LAS. LAS3, DLIS/LIS, comma decimals and proprietary dialects are outside this release. Arbitrary-precision source decimals are preserved in the document but numerical analysis remains finite Double.
No curve alias inference, depth-shift optimization, reservoir interpretation, drilling advice, safety decisions, geological inference or thermodynamic model is provided. QA thresholds and units remain the caller's responsibility. Equal-within-tolerance observations retain the earlier source even under PreferLast. Conflict records identify the previous/incoming observations before policy application. Generated depth cells deliberately have no run owner.

Arrays are readable and mutable; constructors snapshot inputs, transformations rebuild validated copies, and report writers revalidate their input. Do not mutate objects concurrently. Use numerical CSV in data pipelines, not as a safe spreadsheet-formula format for untrusted run names.

See [architecture](docs/architecture.md), [security](SECURITY.md), [references and AI disclosure](SOURCE_ATTRIBUTION.md), [bounded duplication review](docs/competition/duplicate-check.md), and [changelog](CHANGELOG.md). Application/registration materials are deliberately absent from the source package.

## 0.2.0 migration and standards cases

`Curve` record literals now require `api_code: ""` when the optional LAS code is absent. This intentional source incompatibility is why the release is 0.2.0 rather than a replacement of 0.1.0. Metadata descriptions must not contain colons: LAS uses the **last** colon, so embedded colons belong in `Header.value` (or opaque curve data), not in the description. Existing 0.1.0 code using first-colon semantics must migrate explicitly; no silent repair is applied.

`Log.version_headers` contains only additional version headers. `Log.extra_sections` stores uninterpreted customer sections; transformations copy their contents, but do **not** interpret or update embedded vendor depth references. Assembly retains the first run's well/parameter/customer metadata and merges curve API definitions: a later nonempty code fills an empty one; two different nonempty codes are rejected, independent of sample conflict policy. API codes are not a registry lookup or evidence of measurement correctness.

~~~sh
moon run examples/compliance --target wasm-gc --deny-warn
node tools/moonwell.mjs fixtures/las2-api-codes.json
python tools/verify-las2.py  # optional lasio 0.32 metadata oracle
~~~

## 0.3.1 strict document workflows

```moonbit
let document = @well.read_las_document(source)
let diagnostics = @well.check_las2(document)
// Empty diagnostics means the declared 2014 baseline passes within budgets.
let original = @well.document_text(document) // exact source String, never regenerated
let log = @well.document_to_log(document) // can raise model: for valid documents
let output = @well.write_las_strict(log, wrapped=true)
```

The complete [strict public example](examples/strict/main.mbt) covers validation, both WRAP outputs, duplicate-name archival/model rejection and structured missing-header diagnostics. A source capture alone never implies validity. Numeric-model output may not preserve arbitrary decimal spelling: retain the document as the authoritative archive.

```sh
moon run examples/strict --target wasm-gc --deny-warn
moon build --target js --release --deny-warn
python tools/make-conformance-corpus.py
python tools/verify-conformance.py
```

The deterministic 105-case corpus has 27 positives and 78 negatives. Independent Python structure/Decimal and MoonBit verdicts agree; all 105 exact archives match; 22 numerical-model positives survive strict normalization and independent revalidation; 5 standard-valid model-limited cases explicitly reject conversion. This cross-check is not CWLS Certify certification. CI runs it alongside the 32 numerical and 6 metadata lasio oracle cases, tests/builds and all public examples on wasm-gc/wasm/js/native. Windows has no local native C compiler, so native execution is verified in Linux CI, not claimed locally.

Local 0.3.1 measurements: **2964** nonblank/noncomment production MoonBit lines (tests, examples, bridge, generated interfaces excluded); **74/74** tests on each of wasm-gc/wasm/js, strict checks, release builds, public workflows and real CLI acceptance passed. Native strict check passed locally; actual native execution is a CI requirement.
