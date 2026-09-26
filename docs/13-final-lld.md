# I12 — Low-Level Design

## Runtime sequence

1. I1 validates cluster prerequisites.
2. I2 creates governed namespaces, quotas, RBAC and default-deny network policy.
3. I3 establishes GitOps control.
4. I4 validates S3 and Data zones.
5. I5 reconciles Kafka/Strimzi and `transactions.raw`.
6. synthetic JSON events are produced.
7. Polaris exposes the Iceberg REST Catalog.
8. Spark consumes Kafka and writes `polaris.analytics.transactions`.
9. Trino queries the same Iceberg table.
10. Jupyter queries Trino.
11. I10 captures metrics/alerts.
12. I11 provides N3 diagnostics and controlled failure tests.

## Core service endpoints

| Capability | In-cluster target |
|---|---|
| Kafka | `edl-kafka-kafka-bootstrap.edl-data.svc:9092` |
| Polaris | `edl-polaris.edl-data.svc:8181` |
| Trino | `edl-trino.edl-data.svc:8080` |
| Jupyter | OpenShift Route |
| S3 | runtime `S3_ENDPOINT` contract |

## Data contract

Topic: `transactions.raw`

Fields:
- eventId;
- eventTime;
- transactionId;
- amount;
- currency;
- status;
- channel;
- country;
- latencyMs.

Target Iceberg table:
`polaris.analytics.transactions`

## Network model

Baseline:
- deny ingress;
- deny egress;
- DNS only.

Added flows:
- labeled Kafka clients -> Kafka 9092;
- Spark -> Kafka/Polaris/API;
- Spark executor -> driver;
- Trino internal + Polaris;
- Jupyter -> Trino;
- Polaris/Trino/Spark -> approved S3 path.

The CRC portability profile may use broad HTTPS egress on port 443 for API/S3. Production must replace this with approved CIDRs/egress gateway rules.

## Secrets

Runtime only:
- S3 credentials;
- Polaris bootstrap/client credentials;
- Jupyter token.

Target:
- Vault/enterprise secret backend;
- Kubernetes authentication;
- least privilege;
- rotation.

## Recovery

- application state reconciled from Git;
- S3 and catalog require provider-specific backup/recovery;
- CRC does not prove replicated state recovery;
- failure evidence follows I11 runbooks.
