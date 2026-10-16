# Bounded semantic duplication review — 2026-10-14

## Decision and method

Selected MoonWell: original LAS2 well-log integrity plus **unit-aware, conflict-explicit multi-run depth assembly with per-cell lineage**. This is a bounded finding, not an assertion of absolute uniqueness. The installed osc2026-guide Project Research Guide was followed (MoonCakes keyword search, package documentation, linked source/API/tests), while the builder's fixed September contest scope and 2026-10-30 participant deadline remain authoritative.

Three different domains were examined before implementation and reservation. Scores 1–5 are qualitative selection assessments, not measured popularity or performance. Columns: ecosystem breadth, user diversity, reuse, low overlap risk, depth, verifiability, feasibility, maintainability.

| Candidate | B | U | R | O | D | V | F | M | total | hard decision |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Touchstone RF network IO/analysis | 4 | 4 | 5 | 1 | 4 | 5 | 4 | 4 | 31 | rejected: maintained direct substitute |
| MRC/CCP4 volume tools | 4 | 4 | 4 | 2 | 4 | 4 | 3 | 3 | 28 | not selected: substantial MoonNIfTI adjacency |
| LAS2 integrity/run assembly | 4 | 4 | 5 | 4 | 4 | 5 | 4 | 4 | 34 | selected within checked scope |

Hard failures cannot be offset by scores. VCD was discarded at an early registry guard, not counted as one of the three reviewed viable domains.

## Query scope and access limits

Actual moon search queries used --limit 100 --json. Expanded families:

- RF: Touchstone, s-parameter, microwave, network analyzer.
- Volumes: MRC, CCP4, cryo, cryoem, electron microscopy, density map, mrcfile, tomography, NIfTI, DICOM, npy.
- Logs: LAS, well log, welllog, petrophysics, DLIS, CWLS, Log ASCII Standard, geophysical, borehole, logging curves, resample depth, LAS 2.0, lasio, 测井, 井曲线, LAS parser, well log processing, align_logs, moonwell.

GitHub repository search limit 100 included MRC/CCP4/cryoEM/Touchstone and welllog/lasio/borehole/Log ASCII with MoonBit. Code searches used extension:mbt with lasio/CWLS/welllog/CCP4. Official moonbitlang/awesome-moonbit README was read. Zero central-term results are not completeness proof; GitHub only searches indexed repositories/code, not private/unindexed submissions. Fuzzy LAS hits were metadata noise (last/laser); result counts do not establish format support.

The permanent registry was compared using full matching fingerprints, including reserved/completed/rejected/external-checked entries. Prior account projects MoonFountain/MoonSPDX/MoonStix and permanent MoonBench/MoonContract/MoonRecur/MoonShard do not share the core problem. The reservation was written under the shared exclusive lock before implementation. Later unrelated FCA/DNSSEC/WFST reservations were also checked during release review and do not alter this domain boundary.

Raw result snapshots and inspected source fingerprints are retained outside the repository in the participant's local research evidence, not uploaded as a registration attachment. Queries with up to 100 results do not exhaust the ecosystem. Adjacent source/tests were inspected, not executed as project correctness evidence.

## Capability matrix and inspection depth

| Package/version and source | Actual inspected evidence | workflow/behavior | classification and boundary |
|---|---|---|---|
| guolei-dev/touchstone 0.2.1; https://github.com/guolei-dev/moonbit-touchstone | README, public API, analysis and band tests, MoonCakes docs/API | Touchstone RF parameters and analysis | direct substitute for RF candidate; reject RF, not LAS |
| wangjiale6036-dotcom/moonnifti 0.2.0; https://github.com/wangjiale6036-dotcom/moonnifti | README, root and example APIs, module metadata | scientific voxels/coordinate transforms | highly adjacent MRC workflow; not LAS depth curves |
| 2515050243qyf/moonbit-geofield 0.2.0; https://github.com/2515050243qyf/moonbit-geofield | README, root API, advanced and acceptance-edge tests, docs/API | gravity/magnetic/geospatial profiles, interpolation/statistics | real generic numerical overlap, different core workflow; no inspected LAS/run source model |
| hzc-666-ai/moonseis 0.1.0; https://github.com/hzc-666-ai/MoonSeis | README, root API, module metadata | miniSEED3 time waveforms/STA-LTA | same broad geoscience direction, different inputs/index/events |
| hrwqe/cf_ocean 0.1.4; https://github.com/hrwqe/moonbit-cf-ocean | README, dataset and lineage APIs, profile resample source, merge-query tests, module metadata | NetCDF/CF ocean data, temperature/salinity profile resampling, time-series merge, operation lineage | highly adjacent numerical/QC/provenance vocabulary; not the same LAS/run conflict/cell-lineage workflow |

CF Ocean was newly surfaced by release reverse search and inspected before remote creation. It has real depth interpolation and lineage, so it is not dismissed by a different project name. Its ProfileDataset fixes temperature/salinity, profile resampling is reject/clamp with no inspected optional per-curve gap rule, merge_timeseries_datasets rejects duplicate timestamps/incompatible layouts, and lineage records transformation operations. MoonWell instead preserves arbitrary LAS curve schema/nulls, resolves observations from overlapping depth runs under declared unit/conflict rules, and records each output cell's actual run/interpolation decision. Extending the ocean exchange module with borehole LAS semantics would couple distinct format/schema and merging contracts; the independent small portable API is justified on this different workflow, not an allegedly novel interpolation formula. No speed superiority is claimed. CF Ocean remains credited; no code was copied.

MoonWell similarly does not reimplement geofield gravity/magnetic models or MoonSeis waveform algorithms. Generic statistics and linear interpolation are not unique inventions. Domain-specific integrity and explicit assembly decisions are the reusable integration boundary.

## Complete workflows and exclusions

1. Acquisition QC systems: LAS text → bounded metadata/ASCII validation and caller-defined quality rules → deterministic findings and summary report.
2. Research pipelines: depth curves → constrained fill/resampling and clipped interval integration → numerical CSV/canonical LAS plus coverage.
3. Archival/integration systems: named runs and explicit grid/units/policy → conflict-resolved union of curves → canonical table, per-cell sources and pre-policy conflicts.

Out of scope: general GIS, gravity/magnetic modelling, seismic waveforms, reservoir interpretation/drilling/safety advice, LAS3/DLIS/LIS/proprietary decoding, implicit curve aliases and automatic depth-shift optimization. This prevents the project becoming a superficial relabel of adjacent scientific frameworks.

## Release recheck

Before first remote write on 2026-10-14, repeated official MoonCakes searches gave: welllog 0, moonwell 0, petrophysics 0, LAS 41 fuzzy results, resample depth 2, align_logs 2. resample depth surfaced CF Ocean and generic certified algorithms; align_logs returned GUI/games metadata, not well-log alignment. GitHub welllog+MoonBit repository search returned total_count 0 and incomplete_results false. Central interface families were reverse searched during initial selection (align_logs, resample depth, well log processing, LAS parser); the documented own assemble/sample/missing_spans workflow was compared against all adjacent public interfaces.

No maintained direct replacement for the combined selected workflow was found **within these recorded searches and source inspections**. This is not an official organizer ruling or full ecosystem proof. CWLS legacy LAS2 PDF/product URLs were inaccessible; accessible lasio documentation supports only a declared tested subset. No claim of universal LAS compatibility is made.

## 2026-10-16 maintenance-release recheck

The same existing project's 0.2.0 addresses LAS2 API-code preservation; no new topic was selected. `moon search las --limit 30` and `moon search "well log" --limit 30` surfaced MoonWell 0.1.0 and largely lexical matches (for example distributed Raft logs and optical lasers), not a newly identified direct LAS/run-assembly replacement. GitHub repository search `language:MoonBit LAS well`, first 30 results, reported total_count=0, which also failed to surface this known project and is therefore weak negative evidence, not proof of absence. This bounded maintenance recheck does not replace the original adjacent-source comparison or establish uniqueness. Standards research has since obtained the primary CWLS January 2014 document via the lasio mirror; see ../las2-conformance.md for the new evidence and open full-compliance gate.
