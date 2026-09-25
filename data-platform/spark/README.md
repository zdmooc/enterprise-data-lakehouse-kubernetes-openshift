# I6 — Apache Spark on Kubernetes / OpenShift

## Baseline

- Apache Spark: **4.2.0**
- execution: native Spark Kubernetes backend with `spark-submit`
- local proof: one driver + one executor
- namespace: `edl-data`
- service account: `spark-runner`

Spark 4.2.0 documentation requires Kubernetes >= 1.34 and Kubernetes DNS. The driver service account must be allowed to create/manage pods, services and ConfigMaps.

## Why native Spark first

A Spark Operator is not required to prove Spark-on-Kubernetes fundamentals.

The initial architecture intentionally exposes:
- driver/executor lifecycle;
- RBAC;
- Kubernetes scheduling;
- pod logs;
- resource requests;
- network paths.

An Operator can be evaluated later if the Data Product operating model needs a CRD-based job lifecycle.

## Proof 1 — Spark engine

Deploy:

```bash
oc apply -k data-platform/spark/profiles/crc
```

or:

```bash
bash scripts/test-spark-crc.sh
```

The submit Job runs Spark's bundled `pi.py` in Kubernetes cluster mode.

## Proof 2 — Data Product transformation

Source:

`jobs/transactions_aggregate.py`

The job creates a synthetic transaction dataset, derives latency buckets and aggregates count/amount/latency by status/channel.

A small derived image is defined in:

`image/Dockerfile`

No custom image is claimed published or runtime validated yet.

## S3 integration

I6 initially proves compute independently.

I12 will connect the transformation to the S3 contract:
- raw input;
- curated output;
- Trino query.

This avoids hiding an object-store problem behind a Spark problem.

## OpenShift security

The official Spark image has a default user. OpenShift SCC/arbitrary-UID compatibility must be tested before claiming runtime support. No privileged SCC will be granted merely to make the image start.
