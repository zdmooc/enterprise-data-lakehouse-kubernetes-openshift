# 06 — Cluster Contract

Before a Data component is installed, the target cluster must satisfy a minimum platform contract.

## Mandatory

- API reachable;
- at least one Ready worker/schedulable node;
- cluster DNS functional;
- working CNI;
- namespace/project creation path;
- service account and RBAC APIs;
- persistent-storage strategy;
- workload exposure strategy;
- resource requests/limits supported.

## Kubernetes target

Expected:
- Ingress or documented equivalent;
- PSS/PSA strategy;
- StorageClass/CSI or explicit static-storage alternative.

## OpenShift target

Expected:
- Projects;
- Routes;
- SCC behavior documented;
- Operator/OLM availability documented;
- OpenShift GitOps path documented where used.

## Validation stages

### Stage 1 — Connectivity

Run:

```bash
bash scripts/preflight-cluster.sh
```

### Stage 2 — Workload DNS

Planned:
- temporary namespace;
- client pod;
- service resolution test;
- cleanup.

### Stage 3 — Persistent volume

Planned:
- test PVC;
- write/read;
- restart;
- cleanup.

### Stage 4 — Namespace security

Planned:
- service account;
- namespace-scoped Role/RoleBinding;
- denied cross-namespace operation.

### Stage 5 — NetworkPolicy

Planned:
- default deny;
- explicit allow;
- negative connectivity test.

No Data Platform component is considered deployable until the relevant stages pass.
