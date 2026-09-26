# Enterprise Data Lakehouse on Kubernetes & OpenShift

Reference architecture and hands-on lab for building, industrializing and operating **enterprise Data products on Kubernetes and Red Hat OpenShift**.

The project targets an Architect / Expert Platform posture at the intersection of:

- Kubernetes / OpenShift platform engineering;
- Data & AI infrastructure;
- Lakehouse architecture;
- GitOps and industrialization;
- Security and IAM;
- Observability and SRE;
- Day-2 operations, troubleshooting and N3 support.

> **Important:** this is a personal, synthetic and public engineering lab. It is not an official Crédit Agricole, CA-GIP or customer repository. No customer confidential information, internal configuration, credentials or production data must ever be committed here.

---

## Why this repository exists

The repository is designed around a realistic enterprise need:

> Platform teams provide Kubernetes/OpenShift capabilities and accompany Data teams in the build and industrialization of Data products.

The goal is not to install a list of tools. The goal is to prove an end-to-end operating model:

```text
Business / Data use case
        |
        v
Data Product
        |
        v
Kafka / ingestion
        |
        v
Spark / processing
        |
        v
S3-compatible object storage
        |
        v
Trino / SQL federation
        |
        v
Jupyter / analytics
        |
        v
Consumers / APIs / dashboards
```

All of this must run on a governed platform with GitOps, security, observability, resilience and documented operations.

---

## Two execution targets

### Track A — Kubernetes from scratch

Kubernetes internals are learned and demonstrated through the existing repositories:

- [kubernetes-the-hard-way-vagrant-architect-v29](https://github.com/zdmooc/kubernetes-the-hard-way-vagrant-architect-v29)
- [kubernetes-the-hard-way-multicloud](https://github.com/zdmooc/kubernetes-the-hard-way-multicloud)

This repository **does not duplicate** their PKI, etcd, API server, controller-manager, scheduler, kubelet or bootstrap implementation.

It consumes a working cluster as an execution target.

### Track B — OpenShift

The same Data Platform will progressively be validated on:

1. OpenShift Local / CRC for lightweight local validation;
2. a multi-node OpenShift target when HA, storage and resilience testing require it.

A CRC single-node lab is never presented as production HA evidence.

---

## Target architecture

```text
                        DATA USERS
                Data Engineer / Analyst
                         /      \
                    Jupyter    SQL/API
                         \      /
                          TRINO
                            |
             +--------------+--------------+
             |                             |
           SPARK                         KAFKA
             |                             |
             +--------------+--------------+
                            |
                       MINIO / S3
                            |
                    DATA PRODUCT ZONE

==============================================================

                     PLATFORM SERVICES

  Argo CD | Helm | Kustomize | Vault | OIDC | RBAC
  NetworkPolicy | Policy-as-Code | Image Security
  Prometheus | Grafana | Alertmanager | Loki / OpenSearch

==============================================================

                    EXECUTION LAYER

        Kubernetes from scratch     OpenShift
                 |                      |
        Control Plane / etcd       Operators / SCC
        CNI / CSI / Ingress        Routes / OLM / CSI
```

---

## Initial technology scope

| Capability | Primary candidate |
|---|---|
| Container orchestration | Kubernetes / OpenShift |
| GitOps | Argo CD |
| Packaging | Helm |
| Environment overlays | Kustomize |
| Streaming | Apache Kafka / Strimzi |
| Object storage | S3-compatible / MinIO for lab |
| Data processing | Apache Spark |
| SQL query | Trino |
| Notebook / Data UX | Jupyter |
| Secrets | HashiCorp Vault pattern |
| IAM | OIDC / Keycloak pattern |
| Policy-as-Code | Kyverno / OPA Gatekeeper |
| Metrics | Prometheus |
| Dashboards | Grafana |
| Alerting | Alertmanager |
| Logs | Loki and/or OpenSearch |
| Supply-chain security | Trivy / Grype / Cosign patterns |

Technology choices remain subject to ADR and compatibility validation before implementation.

---

## Repository map

```text
.
├── README.md
├── ROADMAP.md
├── BACKLOG.md
├── docs/
│   ├── 00-vision-and-scope.md
│   ├── 01-target-architecture.md
│   ├── 02-mission-alignment.md
│   ├── 03-reuse-existing-repositories.md
│   ├── 04-lab-strategy.md
│   ├── 05-data-product-demo.md
│   ├── 06-cluster-contract.md
│   └── adr/
├── platform/
│   └── profiles/
│       ├── kthw/
│       └── openshift-crc/
├── scripts/
│   └── preflight-cluster.sh
├── gitops/
├── data-platform/
├── security/
├── observability/
├── runbooks/
└── evidence/
```

Directories are populated progressively. Empty implementation areas are intentionally not advertised as completed.

---

## Engineering rules

1. **No fake evidence.** A manifest is not a deployment proof.
2. **No fake HA.** Single-node CRC is not a high-availability platform.
3. **No secrets in Git.**
4. **No customer confidential material.**
5. **Versions are pinned only after compatibility validation.**
6. **Architecture decisions are documented before multiplying components.**
7. **Every iteration has explicit acceptance criteria.**
8. **Data products drive the platform; tools do not drive the architecture.**

---

## Delivery strategy

The project is developed in progressive iterations:

```text
I0  Architecture & scope                         DONE
I1  Cluster contracts and prerequisites          IMPLEMENTED / RUNTIME PENDING
I2  Platform baseline                             IMPLEMENTED / RUNTIME PENDING
I3  GitOps                                        IMPLEMENTED / RUNTIME PENDING
I4  Object storage                               IMPLEMENTED / RUNTIME PENDING
I5  Kafka streaming                              IMPLEMENTED / RUNTIME PENDING
I6  Spark processing                             IMPLEMENTED / RUNTIME PENDING
I7  Trino query layer                            IMPLEMENTED / RUNTIME PENDING
I8  Jupyter / Data user experience               IMPLEMENTED / RUNTIME PENDING
I9  Security & secrets                           IMPLEMENTED / RUNTIME PENDING
I10 Observability                                IMPLEMENTED / RUNTIME PENDING
I11 Resilience / N3 operations                   IMPLEMENTED / RUNTIME PENDING
I12 End-to-end Data Product demonstration        IMPLEMENTED / RUNTIME PENDING
```

See [ROADMAP.md](ROADMAP.md).

---

## Reuse instead of duplication

This project intentionally reuses knowledge and proven assets from existing specialist repositories.

Examples:

- Kubernetes internals → Kubernetes The Hard Way repositories;
- OpenShift platform patterns → `openshift-platform-blueprints`;
- cluster operations / N3 → `k8s-openshift-cluster-factory`;
- Argo CD → `argocd-complete-masterclass`, `argocd-expert-pack`;
- Kafka / Strimzi → `kafka-data-engineer-kafkaops-topic-service-crc`;
- logging / OpenSearch → `elk-log-data-platform`;
- DevSecOps → `maya-secure-agentic-devsecops-platform`.

See [docs/03-reuse-existing-repositories.md](docs/03-reuse-existing-repositories.md).

---

## Current status

**Iteration I0 — COMPLETED**

Completed:
- scope and architecture;
- mission capability mapping;
- reuse matrix;
- lab strategy;
- end-to-end Data Product scenario;
- prioritized backlog;
- platform profiles;
- evidence rules.

**Iterations I1 and I2 — IMPLEMENTED / RUNTIME VALIDATION PENDING**

Implemented:
- cluster contract;
- full preflight suite: connectivity, DNS, PVC, RBAC, NetworkPolicy;
- platform baseline with namespaces, quotas, limits, RBAC and deny-by-default networking;
- Kubernetes/OpenShift overlays and verification scripts.

I3 GitOps is also implemented in Git: bootstrap, AppProject, Applications, operating conventions, environment strategy, secrets contract and drift/rollback lab.

I4 through I12 are now implemented in Git as executable/design assets: S3 contract, Kafka/Strimzi, Spark, Trino, Jupyter, security, observability, N3/resilience and the final Kafka -> Spark/Iceberg -> S3/Polaris -> Trino -> Jupyter Data Product.

The repository therefore has **I0 complete and I1-I12 implemented**. Runtime validation remains deliberately pending. The next operational phase is to execute the iterations on CRC in controlled order, capture evidence, then move HA-only scenarios to a multi-node target. No unexecuted capability is claimed as tested.

---

## Author

**Zidane Djamal**  
Technical / Solution / Platform Architect  
Kubernetes | OpenShift | GitOps | Data Platform | Cloud Native | Resilience
