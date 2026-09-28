# Kind runtime evidence — validation in progress

Source: audited `ccbb114`, runtime branch `runtime/kind-edl-lab`.
This pack records actual gates; later stages are not inferred from static files.

| Iteration | Implementation | Runtime status | Evidence | Known limitations |
|---|---|---|---|---|
| I1 cluster contract | IMPLEMENTED | RUNTIME_VALIDATED | 04-nodes.txt, i1-contract.txt | No ingress controller; local port-forward access |
| I2 baseline | IMPLEMENTED | RUNTIME_VALIDATED | i2-contract.txt, 16-networkpolicies.txt | Local-path storage; laptop fault domain |
| I3 Argo CD | IMPLEMENTED | DEPLOYED | GitOps runtime proof pending | Upstream single-instance lab |
| I4 S3 | IMPLEMENTED | NOT_TESTED | Pending | RustFS single-node profile |
| I5 Kafka | NOT_TESTED | NOT_TESTED | Pending | Kind adaptation pending |
| I6 Spark/Iceberg | NOT_TESTED | NOT_TESTED | Pending | Kind adaptation pending |
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
