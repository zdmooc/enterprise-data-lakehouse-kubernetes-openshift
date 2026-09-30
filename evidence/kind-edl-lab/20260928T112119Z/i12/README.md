# KIND LOCAL E2E RUNTIME VALIDATED

I12: **IMPLEMENTED / RUNTIME_VALIDATED**, 2026-09-30 UTC.

New event: `E2E-I12-20260930T051236Z-a0adb24c8c95`.
Synthetic transaction: 17.42 EUR, ACCEPTED, E2E, FR, latency 7 ms.
Starting commit: `6ab558b4df06e3fb81600703b2c0a2351ac85bc9`.
Branch/context: `runtime/kind-edl-lab` / `kind-edl-lab`.

## Gate results

| Gate | Actual result | Evidence |
|---|---|---|
| Environment | Requested checks ran before edits: clean expected branch/HEAD, Kind context, three Ready nodes. The file records a repeated capture after I12 harness files were created, explaining its I12-only dirty working tree. | environment.txt |
| Initial health | Existing check-health.py passed: 3 Ready nodes, 48 healthy/completed pods, 6 Bound PVCs, 2 Synced/Healthy Argo applications; Kafka and all expected services Ready. | health-before.txt |
| Unique identifier | Timestamp plus random suffix saved before publication. Trino returned zero rows for it before the producer ran. | transaction.json, trino-before.txt |
| Synthetic producer | One producer pod, one send, acknowledgement with acks=all. No second transaction was published during retries. | producer.txt |
| Kafka | Exact JSON payload reread at transactions.raw, partition 1, offset 0; acknowledgement alone was not accepted. | kafka.txt, kafka-record.json |
| Spark | Final r3 driver and executor Succeeded with exit zero; exact I12 consumption and Iceberg readback asserted; five historical IDs preserved. Same acquired image, no rebuild. | spark.txt, spark-driver-r3.txt, spark-driver-status-r3.json |
| S3 / Iceberg | New Parquet/Avro/metadata objects compared against baseline. Metadata fetched directly from S3 agrees with Polaris snapshot 3607998935123899351; summary reports 6 total records in 2 data files. | s3-iceberg.txt, baseline.json |
| Polaris | quickstart_catalog, analytics namespace and transactions table accessible; S3 contract checked; same table UUID and new current snapshot/metadata path. No Polaris restart or reconstruction during I12. | polaris-before.txt, polaris.txt, polaris-after.json |
| Trino | Targeted query returns exactly one I12 row with all payload fields checked, including timestamp. A separate preservation query returns the five historical IDs plus I12, exactly six rows. | trino.txt |
| Jupyter | Python Trino client executed inside the actual Jupyter pod; same ID, exactly one row, all fields checked. No reliance on HTTP health alone. | jupyter.txt |
| Observability | 21/21 active targets UP, including Kafka/exporter and both Trino roles; authenticated Grafana API succeeds, database=ok. | observability.txt |
| Final health | Existing check-health.py passed: 3 Ready nodes, 56 healthy/completed pods, 6 Bound PVCs, 2 Synced/Healthy Argo applications. No current Failed, Pending, CrashLoopBackOff or ImagePullBackOff pod. | health-after.txt |
| Publication checks | Syntax, required evidence, cross-stage event identity, retained failed-attempt logs, sensitive-data checks and Git whitespace validation. | verification.txt |

Final metadata path:
`s3://edl-lab/curated/analytics/transactions/metadata/00002-b6f6e4da-493e-4b60-a256-3724e784892b.metadata.json`.

## Observed issues, without discarding failed evidence

The first Spark execution consumed the new event and successfully wrote it, but the
existing job uses createOrReplace on the records still retained in Kafka. The five
historical events had aged out: transactions.raw retention is 86,400,000 ms, and
partition 2's earliest and latest offsets were both 5. Partition 1 advanced from
0 to 1 for I12. See retention.txt (configuration, then earliest offsets, then latest).
Consequently the intermediate current snapshot had only the new row. The historical
five rows remained readable in snapshot 8689157227482492877 and their S3 objects.

The I12 wrapper was corrected to read/cache the pre-I12 snapshot, retain those rows,
and union only the newly consumed I12 transaction before writing. This modifies
only the I12 ConfigMap-delivered job; the acquired base lakehouse job is unchanged.
The first preservation attempt (r2) failed before writing because this runtime no
longer supports the snapshot-id reader option. It requires versionAsOf. The corrected
r3 driver and executor succeeded; Spark and Trino prove all six final IDs.

The submit job reported Complete even when the r2 driver failed. The I12 harness
checks the driver's actual phase and container status, so it rejected that attempt.
Its full log, UID and exit code 1 remain in spark-driver-r2.txt and
spark-driver-status-r2.json. After successful r3 execution and SQL validation, only
that failed I12 driver was explicitly deleted; its owned transient resources were
eligible for normal Kubernetes garbage collection. cleanup.txt records this action.
No acquired workload, PVC, namespace or cluster was deleted.

The initial Trino query already returned the right row, but the harness's timestamp
parser rejected the explicit UTC suffix. Parsing was corrected and the real query
was rerun. Its initial failure remains in trino.txt. None of these retries republished
the Kafka transaction, rebuilt an image or restarted Polaris.

## Runtime and reproducibility

The entry point is `bash scripts/e2e-lakehouse-kind.sh`. It guards the context before
writing, then runs prepare, producer, spark, validate, finish. Individual gate names
allow continuation without a second publication. Existing transaction.json prevents
prepare from creating another ID in the same evidence pack; producer uses create,
not apply, to reject reuse of its pod name. A further explicitly chosen Spark attempt
uses `EDL_I12_SPARK_ATTEMPT=rN ... spark-retry`; it reuses the recorded event/baseline.
Use a fresh evidence pack only when intentionally starting another E2E transaction.
The preservation check here is scoped to the original five-event lab fixture.

The validated Spark image configuration digest is
`sha256:88a3dd7d2c1b890ffb3bad012e358d06b6cd8115a4f63010257639fabc3f28bd`.
It was present on all three Kind nodes and matched the acquired image evidence.
The real repository Kafka-to-Iceberg transformation and existing Spark templates
were reused; I12 assertions and historical preservation were mounted in an I12-only
ConfigMap. Completed I12 jobs and successful pods remain as runtime evidence.

## Remaining limitations

- One laptop and local-path volumes; one Kafka broker/controller, replication one.
- Polaris metadata remains in memory and is not durable. It stayed intact during I12.
- Kafka retention is 24 hours. The unmodified base batch job can replace a table with
  only the currently retained events; it is not an archival or exactly-once pipeline.
  The I12 wrapper explicitly preserves its pre-run Iceberg snapshot. No snapshot
  expiration, continuous streaming, backup restore or cross-host recovery was tested.
- Spark logs include existing REST metrics-reporting and restricted deletecollection
  cleanup warnings. They are retained; final driver/executor success and real reads
  are checked separately. RBAC was not broadened and no CVE hardening was performed.
- Consumer-lag/PVC-capacity metric coverage remains unvalidated. Metrics-server is
  absent; kubectl top remains NOT AVAILABLE. Docker stats are not a Metrics API test.
- Known I9 vulnerabilities remain; upstream image scan coverage is unchanged.
- I1-I11 were not rerun. CRC was not accessed, started, stopped or changed. The
  CRC/Kind switch was not tested. edl-lab is preserved and running.

No passwords, tokens, credential values, kubeconfig authentication material or
private keys are intentionally exported. Polaris/Secret responses are held in memory;
only an allow-list of non-secret catalog fields is logged. Verification includes
comparison against live lab credentials and token/private-key patterns.

## Resume checkpoint — 2026-09-30 10:01 UTC

Required Git status/diff/branch and Kind context/nodes/pods checks were repeated
before further work. All local I12 changes were retained. The r3 driver and executor
were already Completed/Succeeded, so no Spark job was rerun and no second Kafka
transaction was published. Read-only validate/finish gates reconfirmed the same
snapshot 3607998935123899351, six total rows, exact I12 reads in Trino/Jupyter,
21 UP targets, Grafana and final cluster health. All earlier failed evidence remains.

For Git publication, trailing whitespace in text logs was normalized; diagnostic messages and failed attempts were retained.
