# JSON command protocol v1

Requests are UTF-8 JSON objects. Unknown keys are errors, including within named runs. All numbers must be finite, grid step and max_gap positive. LAS strings use the declared strict LAS2 subset. No filesystem paths or shell commands occur in the protocol.

| command | required fields besides command | result |
|---|---|---|
| qa | las, max_gap | moonwell.qa/v1; summaries, missing spans and depth-gap findings |
| normalize | las | canonical ascending las |
| csv | las | numerical csv |
| resample | las, start, stop, step, max_gap | canonical las and csv |
| interval | las, curve, start, stop, max_gap | moonwell.interval/v1 |
| assemble | runs, start, stop, step, max_gap, policy, tolerance | las, csv, provenance_csv, assembly |

runs is an array of {name,las} objects. policy is reject, first or last. tolerance is an absolute number >=0. start/stop grid endpoints are inclusive where exactly reached; grids do not add an off-grid stop. Assembly rejects an empty/too-large run list and repeated run names. Synthetic depth source is null. Other missing cells also have null source.

The QA protocol command intentionally uses no curve thresholds; use the library quality_check/quality_report API with explicit QcRule values for range/gradient/constant-run rules. No hidden default geological thresholds exist.

Examples are fixtures/qa.json and fixtures/assemble.json. Library execute always returns one envelope, including malformed-JSON and domain errors. Adapter IO failures are stderr plus exit 2 rather than fake domain envelopes.
