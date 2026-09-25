# I7 — Trino Query Layer

## Baseline

The official Trino project recommends the community Helm chart for Kubernetes.

Initial lab pin:

- Helm chart: **1.42.2**
- Trino server: **480** (the appVersion paired with that chart)

At implementation time Trino 483 is the latest server release. The first lab deliberately keeps the chart/server pair coherent; upgrading 480 -> 483 becomes a lifecycle validation after baseline runtime proof.

## CRC topology

- 1 coordinator
- 1 worker
- TPCH/TPCDS synthetic catalogs
- ClusterIP service
- OpenShift arbitrary-UID-friendly values
- NetworkPolicy enabled

This is a functional/query lab, not performance sizing.

## Install

```bash
bash scripts/install-trino-crc.sh
```

## Query smoke test

```bash
bash scripts/test-trino.sh
```

Expected query:

```sql
SELECT count(*) FROM tpch.tiny.customer;
```

## Why TPCH first?

TPCH isolates the Trino engine from object-storage/catalog complexity.

The sequence is intentional:

1. prove Trino coordinator/worker;
2. prove SQL;
3. connect the S3/lakehouse catalog after I4 storage is runtime available;
4. query Spark-produced curated data during I12.

## OpenShift

The upstream chart defaults to a fixed UID/GID. The CRC values remove that pod-level fixed UID so OpenShift SCC can assign an allowed UID. Runtime evidence is required before claiming compatibility.
