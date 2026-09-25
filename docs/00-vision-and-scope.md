# 00 — Vision and Scope

## Vision

Build a reference platform that demonstrates how an enterprise Kubernetes/OpenShift expert can enable Data teams to build and industrialize Data products.

The central problem is not "how to install Spark". It is:

> How do we provide Data teams with a secure, observable, reproducible and operable platform that lets them deliver Data products without becoming Kubernetes platform experts themselves?

## Primary personas

### Platform Engineer / Kubernetes Expert

Responsibilities:
- cluster and platform capabilities;
- namespaces/projects;
- network and storage primitives;
- policy;
- upgrades;
- observability;
- incident support.

### Data Engineer

Responsibilities:
- ingestion;
- transformation;
- schemas;
- Spark jobs;
- Kafka topics;
- quality controls;
- Data Product delivery.

### Data Analyst / Data Scientist

Responsibilities:
- SQL;
- notebooks;
- exploration;
- controlled access to governed datasets.

### Security / IAM

Responsibilities:
- identities;
- least privilege;
- secrets;
- admission policy;
- audit;
- supply-chain controls.

### SRE / Operations

Responsibilities:
- availability;
- alerts;
- capacity;
- incident response;
- RCA;
- Day-2 operations.

## In scope

- Kubernetes and OpenShift runtime patterns;
- Data workloads on container platforms;
- GitOps;
- Kafka;
- S3-compatible object storage;
- Spark;
- Trino;
- Jupyter;
- security;
- observability;
- resilience;
- support N3;
- deployment and operations documentation.

## Out of scope for the initial iterations

- production sizing claims without production data;
- real customer datasets;
- proprietary internal customer architecture;
- production-grade multi-site disaster recovery claims from a local lab;
- installing every product listed in a recruiter description;
- duplicating the Kubernetes-from-scratch repositories.

## Architecture principle

The project is layered:

```text
DATA PRODUCT
    |
DATA SERVICES
    |
PLATFORM SERVICES
    |
KUBERNETES / OPENSHIFT
    |
INFRASTRUCTURE
```

Each layer exposes a contract to the layer above and is independently observable and operable.
