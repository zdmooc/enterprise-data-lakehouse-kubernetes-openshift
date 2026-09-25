# 01 — Target Architecture

## Architecture objective

Provide a portable enterprise Data Platform architecture that can run on:

- Kubernetes from scratch for deep platform understanding;
- OpenShift for enterprise platform behavior;
- later, a multi-node environment for HA and resilience validation.

## Logical architecture

```text
+--------------------------------------------------------------+
|                         DATA USERS                           |
|  Data Engineer | Analyst | Data Scientist | Platform Team    |
+------------------------------+-------------------------------+
                               |
                               v
+--------------------------------------------------------------+
|                    DATA EXPERIENCE LAYER                     |
|                  Jupyter | SQL | APIs                        |
+------------------------------+-------------------------------+
                               |
                               v
+--------------------------------------------------------------+
|                     QUERY / COMPUTE LAYER                    |
|                       Trino | Spark                           |
+------------------------------+-------------------------------+
                               |
                               v
+--------------------------------------------------------------+
|                 STREAMING / STORAGE LAYER                    |
|                      Kafka | S3/MinIO                         |
+------------------------------+-------------------------------+
                               |
                               v
+--------------------------------------------------------------+
|                    PLATFORM SERVICES                         |
| Argo CD | Helm | Kustomize | Vault | OIDC | Policy-as-Code  |
| Prometheus | Grafana | Alertmanager | Loki/OpenSearch         |
+------------------------------+-------------------------------+
                               |
                               v
+--------------------------------------------------------------+
|                  KUBERNETES / OPENSHIFT                      |
| API | etcd | Scheduler | Workers | CNI | CSI | Ingress/Route  |
+------------------------------+-------------------------------+
                               |
                               v
+--------------------------------------------------------------+
|                   INFRASTRUCTURE LAYER                       |
| Compute | Network | Storage | DNS | Load Balancer | PKI       |
+--------------------------------------------------------------+
```

## Platform boundaries

### Cluster layer

Owns:
- control plane;
- nodes;
- CNI;
- CSI;
- DNS;
- ingress/route primitives;
- cluster lifecycle.

### Platform services layer

Owns:
- GitOps;
- namespace/project factory;
- identity integration;
- secrets;
- policy;
- observability;
- shared platform controls.

### Data platform layer

Owns reusable Data capabilities:
- event streaming;
- object storage;
- distributed compute;
- query engine;
- notebook experience.

### Data Product layer

Owns:
- schemas;
- topics;
- transformation logic;
- data quality;
- product-specific datasets;
- SLIs/SLOs;
- user-facing interfaces.

## Multi-tenancy principle

A Data Product should not receive cluster-admin privileges.

Preferred model:

```text
Platform Team
    |
    +--> Namespace / Project factory
    |        |
    |        +--> quotas
    |        +--> limits
    |        +--> RBAC
    |        +--> NetworkPolicies
    |        +--> policies
    |
    +--> Shared Data Services
             |
             +--> Kafka
             +--> object storage
             +--> observability
```

Data teams consume governed capabilities through namespace-scoped access and GitOps.

## Data flow

Initial demonstration:

```text
Synthetic payment/event generator
             |
             v
           Kafka
             |
             v
         Spark job
             |
             v
      Raw/Curated S3
             |
             v
           Trino
             |
             v
          Jupyter
```

## Security flow

```text
User / CI identity
       |
      OIDC
       |
      RBAC
       |
 Namespace/Project
       |
 Admission policies
       |
 Workload identity / secret reference
       |
 Vault / secret backend pattern
```

## Observability flow

```text
Cluster + Data workloads
         |
         +--> metrics --> Prometheus --> Grafana / Alertmanager
         |
         +--> logs ----> Loki/OpenSearch
         |
         +--> events ---> Kubernetes/OpenShift event stream
```

## OpenShift-specific concerns

OpenShift profile must explicitly cover:
- Projects;
- Routes;
- SCC;
- Operators / OLM;
- OpenShift GitOps;
- built-in monitoring constraints;
- image registry/integration patterns;
- security context differences from vanilla Kubernetes.

## Architecture decisions to formalize

ADRs will cover at minimum:
1. App-of-Apps vs ApplicationSet;
2. MinIO as lab S3 implementation;
3. Strimzi for Kafka;
4. Spark deployment model;
5. Trino catalog strategy;
6. Jupyter deployment model;
7. Vault integration approach;
8. Loki vs OpenSearch role split;
9. Kubernetes vs OpenShift portability boundaries;
10. optional Iceberg integration after base flow is validated.
