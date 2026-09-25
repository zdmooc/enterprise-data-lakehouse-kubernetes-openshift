# 05 — Flagship Data Product Demo

## Scenario

Build a synthetic real-time transaction analytics Data Product.

No real banking or customer data is used.

## Business question

Provide near-real-time visibility into transaction activity by:
- event count;
- amount;
- status;
- channel;
- country;
- latency bucket.

The goal is not banking functional accuracy. The scenario exists to exercise the Data Platform.

## Event model

Example synthetic event:

```json
{
  "eventId": "uuid",
  "eventTime": "2026-09-25T14:00:00Z",
  "transactionId": "txn-000001",
  "amount": 125.40,
  "currency": "EUR",
  "status": "ACCEPTED",
  "channel": "MOBILE",
  "country": "FR",
  "latencyMs": 84
}
```

## Pipeline

```text
Generator
   |
   v
Kafka topic: transactions.raw
   |
   v
Spark processing
   |
   +--> validation
   +--> normalization
   +--> aggregation
   |
   v
S3 / MinIO
   |
   +--> raw/
   +--> curated/
   |
   v
Trino
   |
   v
Jupyter
```

## Platform requirements exercised

### Kubernetes/OpenShift

- namespaces/projects;
- RBAC;
- quotas;
- limits;
- service accounts;
- NetworkPolicies;
- storage;
- routes/ingress;
- scheduling.

### GitOps

- declarative deployment;
- environment overlays;
- drift detection;
- rollback.

### Kafka

- topic lifecycle;
- producer/consumer;
- persistence;
- resource constraints;
- monitoring.

### Spark

- driver/executor;
- service account;
- resource allocation;
- failure handling;
- object storage integration.

### MinIO/S3

- buckets;
- credentials;
- persistence;
- data zones.

### Trino

- catalog;
- SQL access;
- concurrency;
- query monitoring.

### Jupyter

- controlled user-facing analysis;
- namespace resource governance;
- SQL/data access.

### Security

Negative tests should later include:
- unauthorized namespace access;
- unauthorized Kafka topic access;
- blocked network path;
- unapproved image;
- missing/invalid secret.

### Observability

Pipeline dashboard should answer:
- is ingestion alive?
- is Kafka lag increasing?
- did Spark complete?
- is object storage reachable?
- are Trino queries failing?
- are workloads throttled/OOMKilled?

## Demo acceptance criteria

The final demo is accepted when:

1. a synthetic event is produced;
2. it reaches Kafka;
3. Spark transforms it;
4. transformed Data is written to object storage;
5. Trino queries the curated dataset;
6. Jupyter displays a result;
7. GitOps owns the deployment state;
8. monitoring exposes component health;
9. one controlled failure is injected and diagnosed;
10. the result is documented under `evidence/`.
