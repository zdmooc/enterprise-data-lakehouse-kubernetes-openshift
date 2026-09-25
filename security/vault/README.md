# Vault Integration Pattern

## Current verified upstream baseline

At implementation time the official HashiCorp chart documents:

- chart 0.34.1
- Vault 2.0.4

## Purpose

Vault is a **secret backend**, not a YAML secret generator committed to Git.

Target flow:

```text
Workload ServiceAccount
        |
Kubernetes auth
        |
      Vault
        |
policy-bound secret path
        |
short-lived / rotated credential
```

## Target paths

Examples only:

- `kv/edl/kafka/...`
- `kv/edl/object-storage/...`
- `kv/edl/trino/...`

No real secret values belong in this repository.

## CRC profile

If Vault is deployed locally, standalone/dev-style modes are **lab only**. HashiCorp explicitly warns that single-server standalone storage is not a production topology.

Production target requires:
- HA storage;
- TLS;
- auto-unseal/KMS or equivalent;
- audit devices;
- backup/recovery;
- least-privilege policies;
- Kubernetes auth;
- rotation;
- monitoring.

## Implementation sequence

1. install Vault lab instance;
2. enable Kubernetes auth;
3. bind `edl-data` service accounts to dedicated Vault roles;
4. prove positive secret retrieval;
5. prove a different service account is denied;
6. remove static S3/Kafka credentials from workload manifests;
7. capture evidence.
