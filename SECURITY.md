# Security and data integrity

This project processes supplied numerical well logs, not safety-critical decisions. No secrets, credential store, network access or filesystem access is in the portable core. The Node adapter only reads an explicitly named bounded regular request file and exclusively creates an optional response file. It never runs input as code or shells out. The generated bridge is trusted build output.

Limits reduce accidental excessive allocations; hostile callers must additionally enforce OS-level resource/time limits. Reports validate mutable arrays, but concurrent mutation is not supported. LAS writer rejects sentinel collisions, metadata delimiter injection and invalid grids rather than silently changing observations. CSV quotes are structural escaping, not spreadsheet formula sanitization; untrusted run names should remain in JSON or be sanitized by spreadsheet consumers.

Do not put confidential commercial well logs, credentials, registration documents or contact information in issue attachments. Report a reproducible problem using synthetic minimized inputs. The code and test corpus are original synthetic content. No claim of audited security or complete LAS compatibility is made.
