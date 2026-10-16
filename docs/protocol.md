# JSON command protocol v1

Requests are UTF-8 JSON objects. Unknown keys are errors, including within named runs. All numbers must be finite, grid step and max_gap positive. Compatibility commands accept the numerical reader dialect; successful parsing is not standard conformance. Strict commands freeze CWLS January 2014. No filesystem paths or shell commands occur in the protocol.

| command | required fields besides command | result |
|---|---|---|
| qa | las, max_gap | moonwell.qa/v1; summaries, missing spans and depth-gap findings |
| normalize | las | compatibility canonical ascending las |
| validate-las2 | las | baseline, valid, diagnostics (kind/clause/section/line/field/message) |
| archive-las2 | las | exact original las plus validation report |
| strict-normalize | las | strictly validated numeric-model las, no exponent output |
| csv | las | numerical csv |
| resample | las, start, stop, step, max_gap | canonical las and csv |
| interval | las, curve, start, stop, max_gap | moonwell.interval/v1 |
| assemble | runs, start, stop, step, max_gap, policy, tolerance | las, csv, provenance_csv, assembly |

runs is an array of {name,las} objects. policy is reject, first or last. tolerance is an absolute number >=0. start/stop grid endpoints are inclusive where exactly reached; grids do not add an off-grid stop. Assembly rejects an empty/too-large run list and repeated run names. Synthetic depth source is null. Other missing cells also have null source.

The QA protocol command intentionally uses no curve thresholds; use the library quality_check/quality_report API with explicit QcRule values for range/gradient/constant-run rules. No hidden default geological thresholds exist.

Examples are fixtures/qa.json and fixtures/assemble.json. Library execute always returns one envelope, including malformed-JSON and domain errors. Adapter IO failures are stderr plus exit 2 rather than fake domain envelopes.

A failed standard verdict is a successful `validate-las2` request (`ok:true`, `valid:false`), not an adapter failure. Source capture resource overflow and strict-normalize conversion failures produce `ok:false`. Diagnostics distinguish `standard` and `resource`; valid documents outside Log representation produce `model:` errors during strict-normalize. Archive accepts invalid source too and never calls its capture a validity certificate. Strict normalization preserves record direction; it does not invent missing headers, repair data, or imply exact textual archival.
