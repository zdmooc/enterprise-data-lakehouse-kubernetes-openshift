# Kind runtime evidence — validation in progress

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
| I10 observability | IMPLEMENTED | NOT_TESTED | Pending | Metrics API absent; Docker stats available |
| I11 recovery | IMPLEMENTED | NOT_TESTED | Pending | No multi-host HA claim |
| I12 E2E | IMPLEMENTED | NOT_TESTED | Pending | Full chain not yet deployed |

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
