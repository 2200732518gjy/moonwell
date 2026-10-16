# References, licensing and AI use

Original MoonBit implementation, MIT license. No upstream implementation was translated or copied. Production dependency is the bundled official moonbitlang/core (string/JSON and builtins). All LAS fixtures are handwritten or deterministically generated synthetic data, with no third-party logging dataset.

Design references: lasio documentation for header, data and writing semantics:
- https://lasio.readthedocs.io/en/latest/header-section.html
- https://lasio.readthedocs.io/en/latest/data-section.html
- https://lasio.readthedocs.io/en/latest/writing.html

lasio 0.32 (MIT) and NumPy 2.3.5 (BSD) were used only as optional independent test oracles. Their source is not bundled or used at runtime. 32 synthetic cases matched numerical output, including descending data, nulls and wrapped four-column records. Two-column wrapped LAS was not included in the oracle corpus: the observed lasio auto-column inspection read its single-value lines as one-column data. Our wrapped two-column behavior is tested independently, not falsely described as oracle-verified.

For the 0.2.0 standards review we obtained the CWLS-authored **LAS Version 2.0: A Digital Standard for Logs, Update January 2014**, from the lasio standards mirror:
- https://github.com/kinverarity1/lasio/blob/main/standards/LAS_20_Update_Jan2014.pdf
- PDF SHA256: `48c9bc54c782f374ef4e43d8a8bb10152b487217f099ff729897a6c89a1d7fda`

This is a primary standards document hosted by a third-party mirror, not a normative claim based on lasio's implementation. Direct CWLS HTTPS retrieval failed certificate validation on 2026-10-16; verification was not disabled. The January 2017 update has not been obtained or reconciled, so we explicitly identify the 2014 baseline and do not claim latest-edition or complete certification. The normative PDF is retained privately for review, not redistributed in the source package. See docs/las2-conformance.md for section-by-section implementation, gaps and completion criteria. The independently authored synthetic fixtures reproduce field structure, not a third-party well dataset.

AI disclosure: Codex assisted topic research, original code, tests, documentation and delivery automation. The participant account owns the repository. Tests/CI/oracle checks provide bounded evidence; AI assistance and passing tests do not prove domain correctness, standard conformance or safety. No invented benchmark or performance advantage is claimed.

Adjacent packages were read for semantic duplication review, not copied: Touchstone, MoonNIfTI, MoonBit geofield, MoonSeis and CF Ocean. See docs/competition/duplicate-check.md.
