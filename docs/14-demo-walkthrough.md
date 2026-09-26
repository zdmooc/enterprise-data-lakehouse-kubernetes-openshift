# Final Demo Walkthrough

## 12-minute architecture demo

### 1 — Business/Data objective
Show that the platform industrializes a Data Product, not a catalogue of tools.

### 2 — Platform governance
Show:
- namespaces;
- quotas;
- RBAC;
- default-deny NetworkPolicy;
- explicit Data Product flows.

### 3 — GitOps
Show:
- AppProject;
- Applications;
- sync/health;
- drift/self-heal evidence when runtime validated.

### 4 — Streaming
Show:
- Strimzi/Kafka;
- `transactions.raw`;
- synthetic JSON producer;
- consumer proof.

### 5 — Processing/Lakehouse
Show:
- Spark driver/executor;
- Iceberg table;
- Polaris REST Catalog;
- S3 zones.

### 6 — Query/Data UX
Show:
- Trino query;
- Jupyter result.

### 7 — Security
Show five negative tests:
- Secret read denied;
- Pod delete denied;
- latest-tag rejected;
- privileged Pod rejected;
- hostNetwork Pod rejected.

### 8 — Observability/N3
Show:
- dashboard assets;
- alerts;
- runbooks;
- diagnostics;
- controlled pod-recovery example.

### 9 — Architecture limits
State explicitly:
- CRC = single-node functional lab;
- no fake Kafka HA;
- no fake storage HA;
- multi-node resilience remains a separate validation target.

## One-command runtime flow

After prerequisites and S3 variables are prepared:

```bash
export CONFIRM_EDL_E2E=yes
bash scripts/e2e-lakehouse-crc.sh
```

Do not run this while another resource-heavy CRC test is active unless capacity has been checked.
