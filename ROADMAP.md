# Roadmap

## Delivery principle

Each iteration must produce four things:

1. architecture decision or design update;
2. executable artifact;
3. verification procedure;
4. evidence of the result.

Status vocabulary:

`PLANNED -> DESIGNED -> IMPLEMENTED -> TESTED -> RUNTIME_VALIDATED`

Documentation alone never upgrades a status beyond `DESIGNED`.

---

## I0 — Architecture & scope

**Status:** IN PROGRESS

Objectives:
- define mission-aligned scope;
- define target architecture;
- define reuse strategy;
- define Data Product demo;
- define local and multi-node execution profiles;
- create implementation backlog.

Exit criteria:
- architecture documented;
- backlog prioritized;
- no duplicated Kubernetes-from-scratch implementation;
- resource constraints explicitly documented.

---

## I1 — Cluster contracts & prerequisites

Define the contract expected from a target cluster.

Capabilities:
- working CNI;
- default StorageClass or documented storage path;
- ingress/route exposure;
- DNS;
- metrics availability;
- namespace/project provisioning;
- RBAC;
- support for Operators where applicable.

Targets:
- KTHW/Vagrant Kubernetes;
- OpenShift Local / CRC.

Exit criteria:
- preflight script;
- target profile documentation;
- evidence template.

---

## I2 — Platform baseline

Deliver:
- namespaces/projects;
- ResourceQuota / LimitRange;
- RBAC;
- default-deny NetworkPolicies;
- security contexts / OpenShift SCC mapping;
- base labels and annotations;
- storage classes abstraction;
- baseline health checks.

Exit criteria:
- repeatable baseline;
- validation script;
- clean uninstall/reset procedure.

---

## I3 — GitOps foundation

Deliver:
- Argo CD;
- AppProject model;
- ApplicationSet or App-of-Apps decision;
- Helm/Kustomize conventions;
- dev/preprod/prod-like overlays;
- secrets integration strategy.

Exit criteria:
- Git-driven deployment;
- drift detection;
- rollback/reconciliation lab.

---

## I4 — Object storage

Lab target:
- S3-compatible MinIO.

Learn and prove:
- object storage concepts;
- buckets;
- credentials;
- persistence;
- encryption/TLS pattern;
- access from Data workloads;
- backup/restore considerations.

Exit criteria:
- Data zone bucket structure;
- smoke tests;
- metrics integrated.

---

## I5 — Kafka streaming

Lab target:
- Apache Kafka through Strimzi where supported.

Deliver:
- operator installation path;
- Kafka cluster;
- topics;
- producer/consumer test;
- persistence;
- quotas/security baseline;
- observability;
- incident runbook.

Reuse:
- `kafka-data-engineer-kafkaops-topic-service-crc`.

---

## I6 — Spark processing

Deliver:
- Spark execution model on Kubernetes/OpenShift;
- driver/executor RBAC;
- resource requests/limits;
- S3 access;
- sample batch transformation;
- event/stream processing comparison;
- troubleshooting runbook.

Exit criteria:
- reproducible transformation from raw to curated data.

---

## I7 — Trino query layer

Deliver:
- Trino;
- S3-backed catalog pattern;
- SQL query over curated Data;
- resource and concurrency observations;
- authentication pattern;
- query observability.

Exit criteria:
- SQL query validated against lakehouse data.

---

## I8 — Jupyter / Data user experience

Deliver:
- Jupyter;
- namespace isolation;
- access to Trino/S3/Spark where justified;
- resource quotas;
- persistent workspace pattern;
- user authentication model.

Exit criteria:
- notebook can query or analyze the sample Data Product.

---

## I9 — Security & secrets

Deliver:
- Vault integration pattern;
- OIDC / Keycloak pattern;
- RBAC;
- SCC/PSS mapping;
- NetworkPolicies;
- Kyverno / Gatekeeper;
- image scanning;
- signed-image verification design.

Exit criteria:
- at least five negative security tests documented and executed.

---

## I10 — Observability

Deliver:
- Prometheus;
- Grafana;
- Alertmanager;
- Loki and/or OpenSearch;
- platform + Data workload dashboard;
- SLI/SLO proposal.

Exit criteria:
- one dashboard for platform health;
- one dashboard for Data pipeline health;
- actionable alerts.

---

## I11 — Resilience & N3 operations

Scenarios:
- worker unavailable;
- pod OOMKilled;
- pending pod;
- storage failure;
- Kafka broker/pod failure;
- DNS issue;
- certificate/secret issue;
- failed GitOps sync;
- Spark job failure;
- Trino degraded query path.

Deliver:
- runbooks;
- evidence;
- RCA template;
- upgrade/migration procedures.

---

## I12 — End-to-end Data Product

Target flow:

```text
Synthetic transactions/events
        |
        v
      Kafka
        |
        v
      Spark
        |
        v
    MinIO / S3
        |
        v
      Trino
        |
        v
     Jupyter
```

The same logical product must be deployable through GitOps on both supported platform profiles, subject to local resource constraints.

Final deliverables:
- HLD;
- LLD;
- ADRs;
- deployment;
- security;
- observability;
- runbooks;
- evidence;
- interview/demo walkthrough.
