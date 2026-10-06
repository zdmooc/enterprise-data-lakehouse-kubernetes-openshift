# Visual demo layer runtime validation — 2026-10-06

## Scope

Runtime validation of the optional browser-oriented visualization layer on the retained
`kind-edl-lab` three-node cluster.

This is a local demo validation only. It does not change the production-readiness truth
boundary of the repository.

## Commands exercised

    CONFIRM_VISUALIZATION=yes bash scripts/kind/visualization.sh

The run completed with:

    [PASS] visual demo layer installed

## Runtime results

Validated during the run:

- three Kind nodes Ready;
- RustFS redeployed with Web Console service port 9001;
- Polaris 1.7.0 upgraded with local browser CORS enabled;
- retained I12 catalog/table remained present with no recovery required;
- Redpanda Console image present on all Kind nodes;
- Apache Polaris Console image present on all Kind nodes;
- `edl-kafka-console` rollout successful;
- `edl-spark-history` rollout successful;
- `edl-polaris-console` rollout successful;
- `ICEBERG_EXPLORER.ipynb` copied into Jupyter;
- Spark smoke/Pi job completed and produced a History Server event log;
- `spark-event-logs` PVC Bound;
- `edl-s3` PVC Bound;
- final health gate: 3 Ready nodes, 45 healthy/completed pods, 7 Bound PVCs,
  2 Synced/Healthy Argo applications.

Observed final visualization deployments:

    edl-kafka-console     1/1
    edl-spark-history     1/1
    edl-polaris-console   1/1

Observed service ports:

    edl-kafka-console     8080/TCP
    edl-spark-history     18080/TCP
    edl-polaris-console   8080/TCP
    edl-s3                9000/TCP,9001/TCP
    edl-polaris           8181/TCP
    edl-trino             8080/TCP

## Data truth retained

Polaris retained the exact I12 catalog/table:

- catalog: `quickstart_catalog`
- namespace: `analytics`
- table: `transactions`
- snapshot: `3607998935123899351`
- table UUID: `8894029f-a135-4248-9464-8af1cd2f8966`

No Kafka replay, Spark rewrite or S3/Iceberg data rewrite was required in this run.

## Non-blocking finding

The Kubernetes Metrics API was unavailable during this run, so `kubectl top` checks
were skipped by the existing health tooling. This did not block the visualization layer
or the final pod/PVC/Argo health gate.

## Browser endpoints

After starting `demo/scripts/04-start-interfaces.sh`:

    Argo CD              https://127.0.0.1:18081
    Kafka / Redpanda     http://127.0.0.1:18082
    Spark History        http://127.0.0.1:18083
    Grafana              http://127.0.0.1:13001
    Prometheus           http://127.0.0.1:19090
    Jupyter              http://127.0.0.1:18888
    Trino                http://127.0.0.1:18080
    Polaris Console      http://127.0.0.1:18182
    RustFS Console       http://127.0.0.1:19001

## Truth boundary

This proves that the visualization components deploy and reach a healthy local runtime
state. Browser behavior and component-by-component functional exploration are the next
demo step and are not claimed by this evidence file until exercised.
