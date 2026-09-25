# I5 — Kafka / Strimzi

## Pinned lab baseline

- Strimzi Kafka Operator: **1.2.0**
- Kafka: **4.3.1**
- Strimzi CRD API: **kafka.strimzi.io/v1**

The versions were selected against the current Strimzi release line at implementation time.

## CRC profile

The local CRC profile intentionally uses:

- one dual-role KRaft node;
- 2 GiB PVC;
- replication factor 1.

This proves:
- Operator lifecycle;
- Kafka CR reconciliation;
- persistence;
- topics;
- producer/consumer flow.

It does **not** prove Kafka HA.

## Install Strimzi

```bash
bash scripts/install-strimzi.sh
```

## Deploy CRC Kafka

Direct:

```bash
bash scripts/deploy-kafka-crc.sh
```

or later through Argo CD.

## Smoke test

```bash
bash scripts/test-kafka.sh
```

Expected flow:

`producer -> transactions.raw -> consumer`

## Future multi-node profile

I11 will add a multi-node profile for:
- 3+ nodes;
- replication factor 3;
- min ISR;
- broker loss;
- node loss;
- PDB behavior;
- recovery timing.

## Specialist repository

Deep Kafka operations, Topic-as-a-Service and runbooks remain in:

`zdmooc/kafka-data-engineer-kafkaops-topic-service-crc`
