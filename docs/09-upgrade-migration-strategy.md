# 09 — Upgrade and Migration Strategy

## Principle

Upgrade one layer at a time and preserve a tested rollback/recovery path.

## Order

1. cluster/platform compatibility;
2. Operators/CRDs;
3. shared platform services;
4. Kafka;
5. object storage/catalog;
6. Spark runtime;
7. Trino;
8. Jupyter images/clients;
9. policies/observability.

## Before upgrade

- supported-version matrix;
- deprecated API scan;
- backup/export where applicable;
- capacity headroom;
- health baseline;
- smoke tests;
- Git tag/commit;
- rollback or restore plan.

## Canary

Use a non-production profile first.

For OpenShift/Kubernetes:
- platform canary/lab;
- then non-critical Data Product;
- then production-like environment.

## Kafka

Validate:
- Strimzi upgrade path;
- Kafka supported versions;
- metadata version;
- broker/controller health;
- producer/consumer continuity.

Do not raise Kafka metadata version until rollback implications are understood.

## Trino

Separate:
- Helm chart upgrade;
- Trino server upgrade;
- catalog/connector compatibility.

The initial lab intentionally starts with chart/server versions known to be paired.

## Spark/Iceberg

Validate exact Spark/Iceberg runtime compatibility before changing either version.

## Evidence

Every upgrade test records:
- from/to version;
- pre-health;
- migration actions;
- downtime/impact observed;
- post-health;
- rollback result if tested.
