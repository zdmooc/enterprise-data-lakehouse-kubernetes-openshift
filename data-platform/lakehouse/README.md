# I12 — End-to-End Data Product

## Runtime chain

```text
Synthetic transaction events
          |
          v
     Kafka / Strimzi
          |
          v
Spark 4.1.3 + Iceberg 1.11
          |
          v
Apache Polaris REST Catalog
          |
          v
 S3-compatible object storage
          |
          v
        Trino
          |
          v
       Jupyter
```

## Why Spark 4.1.3 here?

I6 proves the current Spark 4.2 engine on Kubernetes.

I12 is a Lakehouse interoperability profile. Iceberg 1.11.0 officially supports Spark 4.1, so the integrated profile pins Spark 4.1.3 + Iceberg 1.11.0.

Do not silently mix Spark 4.2 with an Iceberg release that does not officially support it.

## Preconditions

Runtime-validated:
- I1 cluster contract;
- I2 baseline;
- I3 GitOps as applicable;
- I4 S3 provider;
- I5 Kafka;
- Polaris installed/catalog created.

Implemented:
- Spark Lakehouse image;
- transaction job;
- Trino Polaris catalog;
- Jupyter Trino client.

## Run

After exporting the I4 S3 variables:

```bash
bash scripts/e2e-lakehouse-crc.sh
```

## Acceptance

The test passes only when:
1. events are produced to Kafka;
2. Spark consumes at least one event;
3. Spark creates/replaces `polaris.analytics.transactions`;
4. Trino returns rows from the same Iceberg table;
5. Jupyter can query the table through Trino when Jupyter is deployed;
6. runtime evidence is captured.

## Not production claims

CRC remains single-node. The integrated test proves component interoperability, not:
- Kafka HA;
- catalog HA;
- storage HA;
- worker-loss resilience;
- production throughput;
- multi-zone DR.
