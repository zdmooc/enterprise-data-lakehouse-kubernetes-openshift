# Runbook — Trino Query Failure / Degradation

## Signal

- SQL query fails;
- coordinator unavailable;
- worker missing;
- queued/running queries grow;
- Iceberg catalog unavailable;
- object-store errors.

## Triage

```bash
oc -n edl-data get pod,svc -l app.kubernetes.io/name=trino
oc -n edl-data logs deployment/edl-trino --tail=200
oc -n edl-data get events --sort-by=.lastTimestamp | tail -50
bash scripts/test-trino.sh
```

## Separate failure domains

### Engine
- coordinator/worker health;
- JVM memory;
- worker registration;
- query state.

### Catalog
- REST catalog DNS/connectivity;
- authentication;
- catalog configuration;
- table metadata.

### Object storage
- S3 endpoint;
- credentials;
- bucket;
- TLS;
- network.

### Query/data
- schema mismatch;
- corrupt object;
- unsupported table format;
- permissions.

Do not blame Trino until catalog and object-store dependencies are separated.

## Metrics

Check OpenMetrics `/metrics` and query:
- running queries;
- failed queries;
- worker count;
- memory pressure.
