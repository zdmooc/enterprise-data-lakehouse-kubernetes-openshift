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
| I6 Spark/Iceberg | IMPLEMENTED | NOT_TESTED | Build in progress | Python executable corrected after initial build failure |
| Polaris | NOT_TESTED | NOT_TESTED | Pending | Existing in-memory lab catalog |
| I7 Trino | NOT_TESTED | NOT_TESTED | Pending | Kind adaptation pending |
| I8 Jupyter | NOT_TESTED | NOT_TESTED | Pending | Kind adaptation pending |
| I9 security | NOT_TESTED | NOT_TESTED | Pending | Initial RBAC/NetworkPolicy probes only |
| I10 observability | NOT_TESTED | NOT_TESTED | Pending | Metrics API not installed yet |
| I11 recovery | NOT_TESTED | NOT_TESTED | Pending | No multi-host HA claim |
| I12 E2E | NOT_TESTED | NOT_TESTED | Pending | Full chain not yet deployed |

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
