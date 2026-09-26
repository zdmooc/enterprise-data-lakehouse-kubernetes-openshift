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

**Status:** COMPLETED

Delivered:
- mission-aligned scope;
- target architecture;
- reuse strategy;
- Data Product demo;
- local and multi-node execution profiles;
- prioritized implementation backlog;
- ADR template;
- evidence rules.

Exit criteria:
- [x] architecture documented;
- [x] backlog prioritized;
- [x] no duplicated Kubernetes-from-scratch implementation;
- [x] resource constraints explicitly documented.

---

## I1 — Cluster contracts & prerequisites

**Status:** IMPLEMENTED / RUNTIME VALIDATION PENDING

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

Delivered so far:
- target profile documentation;
- evidence template;
- generic connectivity/readiness preflight.

Remaining:
- runtime execution on a real target;
- DNS workload test;
- PVC write/read/restart test;
- RBAC negative test;
- NetworkPolicy negative/positive test;
- ingress/route validation.

Exit criteria:
- preflight suite;
- target profile documentation;
- runtime evidence.

---

## I2 — Platform baseline

**Status:** IMPLEMENTED / RUNTIME VALIDATION PENDING

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

**Status:** IMPLEMENTED / RUNTIME VALIDATION PENDING

Delivered:
- OpenShift GitOps/Argo CD bootstrap path;
- constrained AppProject model;
- explicit Application model for initial platform ownership;
- ADR deciding Application first, ApplicationSet when real multi-target scale exists;
- Helm/Kustomize conventions;
- logical dev/preprod/prod-like promotion model without fake multi-cluster claims;
- secrets integration contract and Vault target pattern;
- read-only GitOps status check;
- drift/self-heal/Git-revert rollback lab.

Runtime remaining:
- execute bootstrap on a validated target;
- capture Synced/Healthy evidence;
- execute controlled drift/self-heal;
- execute Git change and revert reconciliation.

Exit criteria:
- Git-driven deployment;
- drift detection;
- rollback/reconciliation evidence.

---

## I4 — Object storage

**Status:** IMPLEMENTED / RUNTIME VALIDATION PENDING

Lab target:
- provider-neutral S3-compatible object storage contract;
- current provider selected at runtime; MinIO/AIStor or another maintained S3-compatible implementation may satisfy the contract.

Learn and prove:
- object storage concepts;
- buckets;
- credentials;
- persistence;
- encryption/TLS pattern;
- access from Data workloads;
- backup/restore considerations.

Implemented:
- S3 contract test;
- raw/curated/checkpoints/evidence zone layout;
- provider-neutral bootstrap/verification scripts;
- provider decision ADR and OpenShift compatibility guardrails.

Runtime remaining:
- select/start an approved provider;
- validate persistence, TLS and metrics;
- capture evidence.

Exit criteria:
- Data zone bucket structure;
- smoke tests;
- metrics integrated.

---

## I5 — Kafka streaming

**Status:** IMPLEMENTED / RUNTIME VALIDATION PENDING

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

Implemented:
- Strimzi install path;
- CRC KRaft profile and future multi-node profile;
- topics;
- producer/consumer smoke test;
- persistence configuration;
- explicit NetworkPolicy flows;
- monitoring resources and Kafka incident runbook.

Runtime remaining:
- operator/cluster reconciliation on target;
- producer/consumer evidence;
- multi-node HA deferred to I11 target.

Reuse:
- `kafka-data-engineer-kafkaops-topic-service-crc`.

---

## I6 — Spark processing

**Status:** IMPLEMENTED / RUNTIME VALIDATION PENDING

Deliver:
- Spark execution model on Kubernetes/OpenShift;
- driver/executor RBAC;
- resource requests/limits;
- S3 access;
- sample batch transformation;
- event/stream processing comparison;
- troubleshooting runbook.

Implemented:
- native Spark Kubernetes execution model;
- driver/executor RBAC and NetworkPolicy;
- CRC engine smoke test;
- custom image build path;
- synthetic transaction transformation job;
- Lakehouse Spark/Iceberg profile for I12.

Runtime remaining:
- OpenShift SCC/arbitrary-UID validation;
- engine and transformation evidence.

Exit criteria:
- reproducible transformation from raw to curated data.

---

## I7 — Trino query layer

**Status:** IMPLEMENTED / RUNTIME VALIDATION PENDING

Deliver:
- Trino;
- S3-backed catalog pattern;
- SQL query over curated Data;
- resource and concurrency observations;
- authentication pattern;
- query observability.

Implemented:
- pinned Trino Helm profile;
- CRC coordinator/worker values;
- TPCH smoke query;
- Polaris/Iceberg catalog profile;
- explicit network flows and monitoring integration.

Runtime remaining:
- Helm deployment and query evidence;
- Lakehouse catalog query evidence.

Exit criteria:
- SQL query validated against lakehouse data.

---

## I8 — Jupyter / Data user experience

**Status:** IMPLEMENTED / RUNTIME VALIDATION PENDING

Deliver:
- Jupyter;
- namespace isolation;
- access to Trino/S3/Spark where justified;
- resource quotas;
- persistent workspace pattern;
- user authentication model.

Implemented:
- OpenShift BuildConfig and image;
- PVC-backed workspace;
- Route and NetworkPolicy;
- runtime-generated token;
- Trino smoke query;
- Lakehouse query example;
- pod-recreation persistence test.

Runtime remaining:
- build/deploy on CRC;
- PVC persistence and Trino/Lakehouse query evidence.

Exit criteria:
- notebook can query or analyze the sample Data Product.

---

## I9 — Security & secrets

**Status:** IMPLEMENTED / RUNTIME VALIDATION PENDING

Deliver:
- Vault integration pattern;
- OIDC / Keycloak pattern;
- RBAC;
- SCC/PSS mapping;
- NetworkPolicies;
- Kyverno / Gatekeeper;
- image scanning;
- signed-image verification design.

Implemented:
- Vault and OIDC/Keycloak patterns;
- RBAC and SCC/PSS mapping;
- deny-by-default networking plus explicit flows;
- Kyverno policies;
- Trivy configuration scan and Cosign design;
- five-case negative security suite.

Runtime remaining:
- execute the five negative tests;
- capture scan/admission evidence;
- validate secret rotation/integration when Vault runtime exists.

Exit criteria:
- at least five negative security tests documented and executed.

---

## I10 — Observability

**Status:** IMPLEMENTED / RUNTIME VALIDATION PENDING

Deliver:
- Prometheus;
- Grafana;
- Alertmanager;
- Loki and/or OpenSearch;
- platform + Data workload dashboard;
- SLI/SLO proposal.

Implemented:
- OpenShift User Workload Monitoring reuse model;
- Kafka PodMonitor and Trino ServiceMonitors;
- PrometheusRule alerts;
- platform overview and Data pipeline dashboards;
- logging strategy;
- SLI/SLO proposal.

Runtime remaining:
- apply monitoring resources;
- verify metrics queries/alerts on target;
- tune thresholds from observed data.

Exit criteria:
- one dashboard for platform health;
- one dashboard for Data pipeline health;
- actionable alerts.

---

## I11 — Resilience & N3 operations

**Status:** IMPLEMENTED / RUNTIME VALIDATION PENDING

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

Implemented:
- N3 incident runbooks for GitOps, Kafka, Spark, Trino, storage, nodes/API, scheduling/OOM/image, DNS/NetworkPolicy and secret/certificate;
- read-only N3 diagnostics;
- guarded pod-deletion recovery script;
- RCA template;
- resilience test matrix;
- upgrade/migration strategy;
- evidence template.

Runtime remaining:
- execute selected CRC-safe scenarios;
- execute node/broker/storage HA only on a real multi-node target.

Deliver:
- runbooks;
- evidence;
- RCA template;
- upgrade/migration procedures.

---

## I12 — End-to-end Data Product

**Status:** IMPLEMENTED / RUNTIME VALIDATION PENDING

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

Implemented:
- HLD and LLD;
- architecture ADRs;
- synthetic Kafka transaction producer;
- Spark/Iceberg/Polaris/Trino/Jupyter integration path;
- explicit Data Product networking;
- guarded one-command CRC E2E orchestrator;
- security, observability and N3 integration;
- evidence template;
- interview/demo walkthrough.

Runtime remaining:
- execute the full flow on CRC after resource/capacity check;
- record evidence;
- validate portability/multi-node behavior separately.

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
