# H1 — retained local Kind runtime

Reference finalizer: `scripts/kind/finalize-h1-local.sh`, acquired at
`91037844b53acd733a6fd50a3a2f80fbc7334b10` on `runtime/kind-edl-lab`.
The final scan/runtime result is recorded in `local-runtime-checkpoint.md`.

The retained event is `E2E-I12-20260930T051236Z-a0adb24c8c95`.
The six-row table must retain snapshot `3607998935123899351`, its metadata
location and table UUID. I1–I12 evidence is historical and is not rewritten.

## Evidence map

- `health-before.txt`, `health-after.txt`: nodes, pods, PVCs, Argo and workload health.
- `runtime-hardening-local.txt`, `probe-local.txt`: actual rootfs settings and
  diagnostic PVC/file preservation, including the originally missed probe rollout.
- `spark-regression.txt`: real driver/executor success, read-only roots, existing
  Kafka partition 1 / offset 0 read, six Iceberg rows and disposable table write/read/drop.
- `trino.txt`, `jupyter.txt`, `regression.txt`: exact retained event, six-row count,
  authenticated Jupyter, persistent marker and a real Python kernel query through Trino.
- `s3-contract-local.txt`: hardened AWS CLI 2.37.5 and RustFS PUT/GET/integrity/DELETE
  plus listing/logical-zone checks. Only disposable objects and zone markers are written.
- `polaris.txt`, `polaris-after.json`, `s3-iceberg.txt`: unchanged catalog contract,
  table UUID, snapshot and existing metadata. `NEW_OBJECTS` in the reused read checker
  means objects added since the historical I12 baseline, not new H1 transaction data.
- `observability.txt`: 21 expected targets UP and authenticated Grafana health.
- `trivy-before-summary.txt`, `trivy-after-summary.txt`, `*-scan.txt`: local scan
  counts and HIGH/CRITICAL classifications; occurrences are not unique CVE counts.
- `dependency-decisions.md`, `spark-upstream.txt`: provenance and residual rationale.
- `ci-checkpoint.md`: separate hosted-CI evidence, not a substitute for these local tests.

## Scope and limits

GitPython is upgraded to 3.1.59 in a Kind derivative. Spark remains 4.1.3 with
Iceberg 1.11.0: its H1 image tag aliases the acquired image, with no binary/JAR
substitution. Netty and Derby findings remain UPSTREAM/DEFERRED. Other residual
HIGH/CRITICAL findings are listed explicitly; no blanket risk acceptance is implied.

Kafka, Polaris, Trino, Prometheus, Grafana, cluster components, RustFS and BusyBox
images are NOT_TESTED for H1 vulnerability rescanning. RustFS and the diagnostic
probe receive configuration-only hardening. The base Spark batch's retention and
replace behavior is unchanged; H1 never invokes that batch to rewrite the six-row table.

The lab remains single-laptop Kind with local storage, single-broker Kafka and
in-memory Polaris. No durability, multi-host availability or production approval
is established. Missing consumer-lag/PVC-capacity metrics and Metrics API remain
limitations. The notebook kernel emitted a plaintext local TCP transport warning;
it is retained in the regression log, not hidden as a security PASS.

Raw scan reports/logs remain under ignored `.audit/kind/h1/`. Only filtered finding
metadata and functional outputs are published. H1 does not access CRC; the later
explicitly authorized H2 switch has its own evidence directory and result.
