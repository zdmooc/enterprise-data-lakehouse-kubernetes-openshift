# ADR-002 — S3 contract first; MinIO/AIStor provider decision in 2026

- Status: Accepted
- Date: 2026-09-25

## Context

The mission technology list includes MinIO and the Data Platform needs S3-compatible object storage.

In 2026, the historical open-source `minio/minio` repository and the historical `minio/operator` repository are archived/read-only. MinIO's maintained Kubernetes/OpenShift product path is AIStor and requires its current commercial/licensing model.

Sources checked on 2026-09-25:
- https://github.com/minio/minio/releases
- https://github.com/minio/operator/releases
- https://docs.min.io/aistor/installation/kubernetes/

## Decision

Separate **the platform contract** from **the storage product**.

The Data Platform depends on an S3-compatible contract:
- endpoint;
- bucket;
- credentials/workload identity;
- TLS;
- object PUT/GET/DELETE;
- persistence;
- observability;
- lifecycle/backup considerations.

Provider-specific implementations are overlays.

## Lab profiles

### Preferred supported profile

MinIO AIStor may be used when:
- a valid license is available;
- the selected version supports the target Kubernetes/OpenShift release;
- installation and resource requirements fit the lab.

### Legacy MinIO OSS profile

The archived OSS line is not a production recommendation.

If used at all, it is:
- isolated/local only;
- pinned;
- explicitly labeled legacy;
- never presented as a current supported production target.

### Alternative S3 provider

A maintained S3-compatible provider may be used for local contract testing if AIStor licensing/resources block the lab.

The architecture remains provider-neutral.

## Consequences

Spark, Trino and Data Product code must not depend on MinIO-specific APIs when standard S3 semantics are sufficient.

## Validation

A provider is accepted by I4 only after:
1. bucket creation or provisioning;
2. PUT;
3. GET;
4. object integrity check;
5. pod restart / persistence check where applicable;
6. DELETE;
7. metrics/log visibility;
8. evidence capture.
