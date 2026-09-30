# KIND LOCAL E2E RUNTIME VALIDATED

Source: audited `ccbb114`, runtime branch `runtime/kind-edl-lab`.
This pack records actual gates; later stages are not inferred from static files.

| Iteration | Implementation | Runtime status | Evidence | Known limitations |
|---|---|---|---|---|
| I1 cluster contract | IMPLEMENTED | RUNTIME_VALIDATED | 04-nodes.txt, i1-contract.txt | No ingress controller; local port-forward access |
| I2 baseline | IMPLEMENTED | RUNTIME_VALIDATED | i2-contract.txt, 16-networkpolicies.txt | Local-path storage; laptop fault domain |
| I3 Argo CD | IMPLEMENTED | RUNTIME_VALIDATED | 10-argocd-applications.txt | Upstream single-instance lab; baseline drift healed |
| I4 S3 | IMPLEMENTED | RUNTIME_VALIDATED | i4-s3-contract.txt | RustFS single-node profile; HTTP internal to lab |
| I5 Kafka | IMPLEMENTED | RUNTIME_VALIDATED | 11-kafka.txt | One broker/controller, replication factor one |
| I6 Spark/Iceberg | IMPLEMENTED | RUNTIME_VALIDATED | spark-smoke.txt, spark-lakehouse.txt | Five real Kafka events; batch replay, not exactly-once |
| Polaris | IMPLEMENTED | RUNTIME_VALIDATED | 13-polaris.txt, spark-lakehouse.txt | In-memory lab catalog, not durable |
| I7 Trino | IMPLEMENTED | RUNTIME_VALIDATED | 14-trino.txt | SELECT 1, 25 TPCH nations, five Iceberg transactions |
| I8 Jupyter | IMPLEMENTED | RUNTIME_VALIDATED | 15-jupyter.txt, jupyter-image.txt | Revalidated 2026-09-29 18:37 UTC: Ready pod, Bound PVC, HTTP 200, five actual Iceberg transactions via Trino, retained PVC proof |
| I9 security | IMPLEMENTED | RUNTIME_VALIDATED | 17-security-tests.txt, i9-supply-chain.txt, SECURITY_FINDINGS.md | Five denials passed; scans completed with vulnerabilities remaining; resource policy Audit |
| I10 observability | IMPLEMENTED | RUNTIME_VALIDATED | 18-prometheus-targets.txt, 20-resource-usage.txt | 21/21 targets UP; Grafana API/datasource/dashboards verified; consumer lag and PVC capacity series absent; kubectl top NOT AVAILABLE |
| I11 recovery | IMPLEMENTED | RUNTIME_VALIDATED | i11/README.md, i11/*.txt | KIND_MULTI_NODE_FUNCTIONAL_RECOVERY; seven scenarios; Polaris catalog lost then reconstructed; one laptop/local PVCs |
| I12 E2E | IMPLEMENTED | RUNTIME_VALIDATED | i12/README.md, i12/*.txt | New unique event verified through Kafka/Spark/Iceberg/S3/Polaris/Trino/Jupyter; five historical rows preserved; local batch/runtime scope |

Initial I2 DNS probe used a short name which BusyBox returned as NXDOMAIN. The
probe now uses `kubernetes.default.svc.cluster.local`, also used by I1; rerun passed.
The portable I1 exposure check was fixed to count zero ingress controllers without
aborting under `pipefail`. Its absence remains an explicit warning.

The first S3 integrity job failed because the upstream AWS CLI image lacked `cmp`.
A Kind-only client image adds diffutils; the original S3 scripts then passed without
weakening their comparisons. The failed pod was replaced after diagnosis. Its
unremoved test object is visible in the listing; the successful run proved DELETE
on its own fresh test object. No credentials are present in these logs.

The first Kafka consumer probe's five-second idle timeout expired before receiving
the record. A diagnostic consumer received the exact produced record. The final
probe now obtains the partition offset, reads the fresh record and requires consumer
exit code zero; this test and the existing five-event producer passed.

The lakehouse Docker build failed on `python: not found` in the official Spark image.
Both build-time Python calls now use `python3`; this portable correction also applies
to builds of the existing OpenShift profile. No OpenShift manifest was modified.

The first Trino Helm install exceeded its ten-minute deadline. Both pods subsequently
became Ready with zero restarts. The guarded rerun completed Helm deployment and all
three SQL tests, including the real five-row Iceberg table. No test was skipped.

The controller-manager and scheduler each restarted after losing their leader lease
at approximately 2026-09-29 05:48 UTC. Previous logs show API request deadlines and
lease renewal failure; the underlying host/API interruption is not established.
Both recovered, and subsequent scheduling and SQL checks passed. The Strimzi operator
also previously recovered from a lost lease. These observations are not HA evidence.

During the heavy Jupyter image import, the controller-manager and scheduler restart
counts reached five each. Previous logs show API/etcd timeouts and lease loss around
11:49 UTC. At the next gate both had remained stable for 66 minutes; `/readyz` returned
`ok`, all three nodes were Ready, 38 pods were healthy/completed, four PVCs Bound and
both Argo applications Synced/Healthy. Disk I/O contention during concurrent imports
is a plausible contributor, not an independently proven root cause. No OOM was shown.

Kyverno 1.19.1 exposes policy readiness at `status.conditionStatus.ready`, not a
standard `Ready` condition. The first wrapper wait timed out despite active policies.
After correcting the JSONPath, both policy checks and all five negative tests passed.
The CPU/memory policy remains Audit, with actual pod resource declarations verified.

## I8-only checkpoint — 2026-09-29 18:37 UTC

At the user's request, this checkpoint revalidated only the existing Jupyter
deployment using `scripts/kind/validate-jupyter.sh`. Its pod was Running/Ready with
zero restarts; its 1 Gi PVC was Bound. The running image matched
`sha256:a54e134013fbf00f591451f7a701c855d91188b9d0b1c07cfcf1ac30282a432c`.
The previous import and deployment were already complete, so neither was repeated.
Authenticated HTTP returned 200. The existing notebook sample queried Trino, and a
second query verified the five original event IDs and returned their real Iceberg
transaction rows. The existing workspace persistence marker was still present.

I1-I7 were not rerun, and I9-I12 were not continued in this checkpoint. Earlier
artifacts from those stages are retained as prior work. CRC was not accessed or
modified, and edl-lab was left running. This checkpoint records I8 completion only,
not completion of the entire lab. The requested `git add -A` includes pre-existing
local changes as well as this I8 evidence update.

## I10-only checkpoint — 2026-09-29 18:46 UTC

Started from clean revision `266e9c359f2d64f65c9fae76b447fd8712ba79bc` on
`runtime/kind-edl-lab`, with context `kind-edl-lab` and three Ready nodes.
`scripts/kind/monitoring.sh` and `scripts/kind/test-monitoring.py` were executed.
All four observability pods are Ready. Both Trino ServiceMonitors, both Kafka
PodMonitors and the application PrometheusRule are loaded. All 21 configured scrape
targets are UP: Trino coordinator/worker, Kafka broker/exporter, API server, CoreDNS,
kubelet endpoints, kube-state-metrics, Grafana, Prometheus and its operator/reloader.
No scrape coverage is claimed for components absent from this target list.

The four application rules are loaded with health `ok`, state `inactive`:
`EDLKafkaConsumerLagHigh`, `EDLKafkaUnderReplicatedPartition`, `EDLPodRestartBurst`
and `EDLPVCNearlyFull`. No alert firing or recovery scenario was tested.
Grafana's authenticated API succeeds, its default Prometheus datasource reports
`OK`, and both repository dashboards are available.

I10 corrections: preserve the explicit empty-password Secret key required by the
Operator for Trino's username-only BasicAuth; narrow the Kafka broker PodMonitor
selector so it does not scrape the exporter twice. Runtime assertions now require
all configured targets UP, one broker-monitor target, Ready observability pods and
healthy loaded rules. No existing OpenShift profile was changed.

Limitations: `kafka_consumergroup_lag` and `kubelet_volume_stats_capacity_bytes` have
no active series. Their dependent panels/alerts are not functionally validated;
rule loading alone does not establish that coverage. Metrics-server remains absent:
`kubectl top = NOT AVAILABLE`. Docker stats are separate container-level observations,
not an equivalent to Kubernetes Metrics API. I1-I9 were not rerun, I11-I12 were not
started, CRC was not accessed, and edl-lab remains running.

## I11-only checkpoint — 2026-09-29/30 UTC

Started from clean `e4137cb29274a5d738f4ba1dc8da617df64a1154` on
`runtime/kind-edl-lab`, with context `kind-edl-lab` and three Ready nodes.
Result: **KIND_MULTI_NODE_FUNCTIONAL_RECOVERY**, I11 **RUNTIME_VALIDATED**.
See [the I11 evidence index](i11/README.md) and its seven scenario logs.

Jupyter, Trino worker, Kafka, Polaris and RustFS each received exactly one targeted
pod deletion. New UIDs became Ready; stateful PVC identities remained unchanged.
Jupyter's persistent marker survived, the coordinator stayed healthy during worker
replacement, Kafka accepted and returned a unique smoke event, and RustFS retained
all 15 existing objects with identical sizes/ETags. Fresh S3 PUT/GET/LIST/DELETE and
post-delete absence passed. Argo automatically healed a non-destructive quota drift
(6 -> 7 -> 6), transitioning OutOfSync/Healthy -> Synced/Healthy in 10.2 seconds.

Polaris's catalog was actually lost: its catalog list became empty and Trino's
Iceberg query failed with SCHEMA_NOT_FOUND. The documented resume-data procedure
reconstructed it from retained Kafka records; the catalog and exactly five original
transactions were verified afterwards. **This does not validate Polaris durability.**
The initial port-forward collision and S3 harness failures remain in the logs with
their corrections; no failed assertion was silently discarded.

N3 collected pods/events/nodes/storage/network/Argo state and verified DNS, the PVC
marker and real SQL reads. Final nodes/pods/PVCs/Argo gates passed. Transient probe/API
timeouts around 2026-09-30 04:52 UTC and the operator's increased restart count are
recorded without claiming a root cause. This is a single-laptop recovery result;
there was no host/node/storage failure injection or continuity guarantee.

I1-I10 were not rerun. I12 remains NOT_TESTED and was not started. CRC was not
accessed, no PVC or namespace was deleted, and edl-lab remains running.

## I12-only checkpoint — 2026-09-30 UTC

Final status: **KIND LOCAL E2E RUNTIME VALIDATED**.
Started from clean `6ab558b4df06e3fb81600703b2c0a2351ac85bc9` on
`runtime/kind-edl-lab`, context `kind-edl-lab`.
Full evidence and retained failed attempts: [i12/README.md](i12/README.md).

A single new transaction, `E2E-I12-20260930T051236Z-a0adb24c8c95`, was generated,
published and reread with every JSON field compared in transactions.raw at partition 1,
offset 0. Spark consumed that exact event, wrote it through Polaris to Iceberg/S3,
and read it back. The final driver and executor succeeded with the acquired image;
no image was rebuilt. New metadata/Parquet objects were checked against the baseline.
The final S3/Polaris snapshot is `3607998935123899351`, with six total records.

Trino and Jupyter each returned exactly one targeted I12 row, with all payload fields
checked, including timestamp. The five historical IDs also remain in the table.
Polaris retained its catalog and storage contract throughout; no restart or catalog
reconstruction was needed. Post-E2E observability found 21/21 targets UP and Grafana's
authenticated API healthy. Final health: 3 Ready nodes, 56 healthy/completed pods,
6 Bound PVCs, 2 Synced/Healthy Argo applications; no current failed/pending/image-pull
or crash-loop pod.

The first batch exposed a real retention limit: the five original Kafka events had
expired under the 24-hour policy, so createOrReplace initially left only the new row
in the current snapshot. The previous five-row Iceberg snapshot remained readable.
The I12 wrapper now preserves that baseline and unions the new transaction. Its first
preservation retry used an unsupported snapshot-id option; the successful retry uses
versionAsOf. The failed driver log/status were archived before targeted cleanup.
The timestamp parser was also corrected for Trino's UTC suffix. Failed attempts are
retained, and no second event was produced. The base batch job remains unchanged;
its retention/overwrite behavior is documented as a limit, not hidden.

All I1-I12 gates are now RUNTIME_VALIDATED within their stated local scope. This does
not establish durable Polaris metadata, continuous streaming, exactly-once processing
or multi-host availability. Known CVEs and missing metric coverage remain unchanged.
I1-I11 were not rerun, no CVE hardening or CRC/Kind switch was performed, CRC was not
accessed or modified, and edl-lab is preserved.

Resume verification at 2026-09-30 10:01 UTC confirmed the already successful r3
driver/executor, unchanged six-row snapshot, exact Trino/Jupyter event reads and
healthy observability/cluster state. Only read checks were repeated; no Kafka event
was republished and no Spark job or Polaris reconstruction was restarted.

## H1 SECURITY HARDENING

Result: **COMPLETED_WITH_REMAINING_FINDINGS**. The local finalizer passed against
the retained I12 runtime on 2026-09-30; details are in `h1-security-hardening/`.
I1–I12 statuses and their historical evidence remain unchanged.

Jupyter GitPython 3.1.59 removes CVE-2026-78676. Local scan occurrences change
from 8 CRITICAL / 205 HIGH to 7 CRITICAL / 198 HIGH. AWS CLI 2.37.5 reduces the
S3 client from 213 HIGH to 14 HIGH (zero CRITICAL in both). Spark retains its
acquired binaries: 10 CRITICAL / 278 HIGH remain, including Netty/Derby findings
classified UPSTREAM/DEFERRED. Other upstream images are NOT_TESTED in this scan
checkpoint. The six Kind KSV-0014 manifest findings are reduced to zero, and
read-only roots were checked on the running workloads and Spark driver/executor.
The omitted diagnostic-probe rollout was detected and corrected while preserving
its PVC identity and file hashes; that gate is now included in the finalizer.

Spark smoke, existing Kafka-event read, six-row Iceberg read and disposable
table write/read/drop passed. The original snapshot `3607998935123899351`, table
UUID and metadata location are unchanged. Jupyter's kernel queried the exact I12
event through Trino, its persistent marker survived, and the S3 contract passed.
Final H1 health: 3 Ready nodes, 6 Bound PVCs, 2 Synced/Healthy Argo applications,
21 targets UP and Grafana healthy. No Kafka publish, Polaris reconstruction,
PVC/namespace/cluster deletion or CRC access occurred in H1. Findings and lab
limitations remain explicit; this is not a production approval.
