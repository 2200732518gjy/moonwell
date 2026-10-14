# References, licensing and AI use

Original MoonBit implementation, MIT license. No upstream implementation was translated or copied. Production dependency is the bundled official moonbitlang/core (string/JSON and builtins). All LAS fixtures are handwritten or deterministically generated synthetic data, with no third-party logging dataset.

Design references: lasio documentation for header, data and writing semantics:
- https://lasio.readthedocs.io/en/latest/header-section.html
- https://lasio.readthedocs.io/en/latest/data-section.html
- https://lasio.readthedocs.io/en/latest/writing.html

lasio 0.32 (MIT) and NumPy 2.3.5 (BSD) were used only as optional independent test oracles. Their source is not bundled or used at runtime. 32 synthetic cases matched numerical output, including descending data, nulls and wrapped four-column records. Two-column wrapped LAS was not included in the oracle corpus: the observed lasio auto-column inspection read its single-value lines as one-column data. Our wrapped two-column behavior is tested independently, not falsely described as oracle-verified.

The old CWLS LAS2 PDF/product URLs were inaccessible during this work. The declared strict subset is based on accessible documentation and explicit project tests, not a claim to certify the complete official standard. Standards are references, not copied code or redistributable data.

AI disclosure: Codex assisted topic research, original code, tests, documentation and delivery automation. The participant account owns the repository. Tests/CI/oracle checks provide bounded evidence; AI assistance and passing tests do not prove domain correctness, standard conformance or safety. No invented benchmark or performance advantage is claimed.

Adjacent packages were read for semantic duplication review, not copied: Touchstone, MoonNIfTI, MoonBit geofield, MoonSeis and CF Ocean. See docs/competition/duplicate-check.md.
