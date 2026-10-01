# H1 local runtime checkpoint — 2026-09-30 16:52 UTC

Result: **H1 LOCAL RUNTIME VALIDATED** on retained `kind-edl-lab`.

- Jupyter GitPython CVE-2026-78676: **FIXED** in the hardened image.
- Jupyter scan: 8 CRITICAL / 205 HIGH / 3926 MEDIUM / 316 LOW -> 7 CRITICAL / 198 HIGH / 3923 MEDIUM / 316 LOW.
- S3 client scan: 0 CRITICAL / 213 HIGH / 134 MEDIUM / 10 LOW -> 0 CRITICAL / 14 HIGH / 7 MEDIUM / 0 LOW.
- Spark scan: 10 CRITICAL / 278 HIGH / 3567 MEDIUM / 346 LOW -> 10 CRITICAL / 278 HIGH / 3567 MEDIUM / 346 LOW; Netty/Derby residuals remain classified by the H1 dependency decision as UPSTREAM where applicable.
- Kind writable-root finding KSV-0014: 6 -> 0.
- Hardened Jupyter, RustFS, S3 reader and S3 contract ran with read-only container roots.
- Spark driver/executor regression used the retained I12 event and a disposable Iceberg table; no Kafka event was produced or replayed.
- The exact I12 Polaris snapshot and six-row validated table were preserved.
- Jupyter kernel -> Trino retained-I12 query passed.
- CRC was not accessed by this script.
- No namespace, PVC, Kind cluster or retained application data was deleted.

This is a local POC hardening result, not production approval. Residual image findings remain documented as UPSTREAM or DEFERRED rather than silently accepted.
