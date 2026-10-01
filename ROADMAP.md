# Roadmap

## Status vocabulary

`PLANNED -> DESIGNED -> IMPLEMENTED -> TESTED -> RUNTIME_VALIDATED`

Documentation alone never upgrades a runtime status. Evidence is required under
`evidence/`.

## Validated local target

The completed runtime target is `kind-edl-lab`: one workstation, three Kind nodes,
Calico networking and local-path storage. CRC/OpenShift Local 4.22.7 is retained as a
separate OpenShift environment and was exercised in H2 only as a read-only local
runtime switch target.

This local POC is not a production HA, multi-host DR or durable-catalog proof.

## Delivery status

| Iteration | Scope | Status |
|---|---|---|
| I0 | Architecture, scope, reuse strategy, evidence rules | COMPLETED |
| I1 | Cluster contracts and prerequisites | RUNTIME_VALIDATED |
| I2 | Platform baseline: namespaces, quotas, RBAC, NetworkPolicy | RUNTIME_VALIDATED |
| I3 | GitOps / Argo CD / drift and reconciliation | RUNTIME_VALIDATED |
| I4 | S3-compatible object storage | RUNTIME_VALIDATED |
| I5 | Kafka / Strimzi | RUNTIME_VALIDATED |
| I6 | Spark processing | RUNTIME_VALIDATED |
| I7 | Trino query layer | RUNTIME_VALIDATED |
| I8 | Jupyter / Data user experience | RUNTIME_VALIDATED |
| I9 | Security / Kyverno / negative controls | RUNTIME_VALIDATED |
| I10 | Prometheus / Grafana observability | RUNTIME_VALIDATED |
| I11 | Resilience / N3 functional recovery | RUNTIME_VALIDATED |
| I12 | End-to-end Data Product | RUNTIME_VALIDATED |

## I12 retained proof

The validated flow is:

```text
Synthetic transaction
        |
        v
      Kafka
        |
        v
      Spark
        |
        v
 Iceberg / S3
        |
        v
     Polaris
        |
        v
      Trino
        |
        v
     Jupyter
```

Retained proof includes event
`E2E-I12-20260930T051236Z-a0adb24c8c95`, six Iceberg rows, snapshot
`3607998935123899351`, table UUID
`8894029f-a135-4248-9464-8af1cd2f8966`, Jupyter/Trino verification and
observability evidence.

## H1 — Security hardening

**Status: COMPLETED_WITH_REMAINING_FINDINGS**

Validated:
- Jupyter GitPython remediation;
- read-only root filesystem contracts;
- reduced-risk S3 client;
- Kind KSV-0014 manifest findings reduced to zero;
- Spark regression checks against retained I12 state;
- Jupyter -> Trino -> I12;
- 3 Ready nodes, 6 Bound PVCs, Argo Synced/Healthy;
- 21 Prometheus targets UP and Grafana healthy.

Residual upstream CVEs and known metric-coverage gaps remain explicit. H1 is not a
production security approval.

## H2 — Kind -> CRC -> Kind local switch

**Status: KIND_CRC_KIND_LOCAL_SWITCH_VALIDATED**

Validated:
- exact existing Kind node containers stopped without deletion;
- CRC/OpenShift Local 4.22.7 started and inspected read-only;
- CRC stopped before Kind restart;
- same Kind node containers restarted with preserved Docker IP mapping;
- in-memory Polaris recovered through metadata-only registration of the existing I12
  metadata file when required;
- no Kafka replay, no Spark rerun and no S3/Iceberg data rewrite;
- final state retained six rows, same snapshot and table UUID;
- Jupyter persistence and Jupyter -> Trino -> I12 passed;
- final platform health and observability passed.

Evidence:
`evidence/kind-edl-lab/20260928T112119Z/h2-kind-crc-kind/`.

## Residual / future engineering scope

These are intentionally outside the completed local POC:
- durable Polaris catalog;
- multi-host / multi-AZ HA and DR;
- real worker/node/storage failure domains;
- backup/restore and CSI snapshot proof;
- exactly-once/continuous streaming semantics;
- Vault and OIDC runtime integration;
- Cosign signed-artifact enforcement;
- Falco/NeuVector runtime assessment;
- Grype comparison;
- RKE2/Rancher profile;
- Cilium/BGP/F5 enterprise networking;
- Longhorn/Portworx/Trident storage profiles;
- operator/Kubebuilder implementation.

Those extensions must not be represented as already validated.
