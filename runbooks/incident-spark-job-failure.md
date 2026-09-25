# Runbook — Spark Job Failure

## Signal

- spark-submit Job Failed;
- driver pod Failed;
- executor pod repeatedly exits;
- job completes with incorrect output.

## Triage

```bash
oc -n edl-data get job,pod -o wide
oc -n edl-data get events --sort-by=.lastTimestamp | tail -50
oc -n edl-data logs job/spark-pi-submit
oc -n edl-data get pod -l spark-role=driver
```

Inspect driver logs first, then executor logs.

## Common causes

- driver service account lacks pod/service/configmap permissions;
- driver cannot resolve Kubernetes API or executors;
- NetworkPolicy blocks executor-to-driver path;
- insufficient memory / OOMKilled;
- image pull;
- S3/catalog connectivity;
- incompatible Iceberg/Spark runtime;
- malformed input/schema.

## Verification

Engine smoke:

```bash
bash scripts/test-spark-crc.sh
```

Data Product jobs require a separate correctness test; a successful Pi job does not prove ETL correctness.
