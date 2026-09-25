# ADR-003 — Apache Iceberg + REST Catalog + Apache Polaris

- Status: Accepted for the I12 reference implementation
- Date: 2026-09-25

## Context

S3-compatible object storage alone does not provide a shared table abstraction for Spark and Trino.

The Data Product needs:
- table metadata;
- schema evolution;
- snapshots;
- atomic commits;
- multi-engine interoperability.

## Decision

Use:
- Apache Iceberg as the table format;
- the Iceberg REST Catalog protocol as the engine-facing contract;
- Apache Polaris 1.7.0 as the reference REST Catalog implementation.

## Engine compatibility

The I6 Spark engine smoke remains on Spark 4.2.0.

The Lakehouse/Iceberg profile uses:
- Spark 4.1.3;
- Iceberg 1.11.0;
- Scala 2.13 runtime artifact `iceberg-spark-runtime-4.1_2.13`.

Reason: Iceberg 1.11.0 officially supports Spark through 4.1. Spark 4.2 support belongs to the next Iceberg line and is not used as a released production baseline here.

## Polaris persistence

CRC uses one Polaris replica with `in-memory` persistence for functional integration only.

This is intentionally non-production:
- metadata is lost on Polaris restart;
- replicas cannot be scaled safely with in-memory persistence.

Production target:
- relational JDBC/PostgreSQL metastore;
- shared authentication signing keys;
- multiple replicas;
- backup/recovery;
- OIDC/enterprise identity;
- monitored persistence.

## Authentication

Lab:
- random root client secret generated at runtime;
- credential stored in a Kubernetes Secret;
- no static Polaris password committed to Git.

Target:
- dedicated principals/roles for Spark and Trino;
- least privilege;
- Vault/enterprise secret backend.

## Storage

Polaris catalog storage points at the provider selected by the I4 S3 contract.

Spark and Trino request vended credentials from Polaris where the selected storage integration supports it.

## Validation

I12 requires:
1. S3 provider contract passes;
2. Polaris starts;
3. catalog is created;
4. synthetic events reach Kafka;
5. Spark reads events and commits an Iceberg table;
6. Trino reads the same table through Polaris;
7. Jupyter queries Trino;
8. result count and aggregates are checked;
9. evidence is captured.

## Revisit triggers

- Iceberg 1.12+ is released and Spark 4.2 compatibility is stable;
- production catalog persistence is introduced;
- client organization mandates another Iceberg REST catalog implementation.
