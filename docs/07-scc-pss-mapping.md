# 07 — Kubernetes PSS vs OpenShift SCC

## Why both matter

Kubernetes Pod Security Standards describe portable security expectations.

OpenShift uses Security Context Constraints (SCC) to control which security settings a pod may use.

They are related but not equivalent.

## Baseline intent

The project targets a restricted workload posture:

- no privileged containers;
- no hostPID/hostIPC/hostNetwork by default;
- no privilege escalation;
- run with non-root / arbitrary UID compatibility;
- drop unnecessary capabilities;
- explicit resource requests/limits;
- namespace-scoped service accounts.

## Kubernetes

Namespaces carry:

`pod-security.kubernetes.io/enforce=restricted`

for the portable baseline.

## OpenShift

The lab must observe the SCC selected by OpenShift for each workload.

Validation command examples:

```bash
oc get pod -n edl-data -o yaml
oc adm policy who-can use scc/restricted-v2
```

Do not bind privileged SCCs merely to make a Data product run. Fix the workload image/security context first whenever possible.

## Data workload implications

Kafka, Spark, Trino, MinIO and Jupyter images must be tested for:

- arbitrary UID compatibility;
- writable paths;
- filesystem group requirements;
- Linux capabilities;
- volume permissions.

Any OpenShift-specific exception requires an ADR and evidence.
