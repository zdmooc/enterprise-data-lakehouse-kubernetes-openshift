# Static Audit — 2026-09-27

Scope: `enterprise-data-lakehouse-kubernetes-openshift`

Runtime CRC was intentionally not used.

## Confirmed findings

### P0 — Kafka smoke test polluted the E2E JSON topic

Files:
- `scripts/test-kafka.sh`
- `data-platform/kafka/base/topics.yaml`

Before:
- the smoke test wrote plain text to `transactions.raw`;
- I12 Spark consumes `transactions.raw` as JSON.

Fix:
- dedicated `transactions.smoke` topic;
- smoke producer/consumer use only that topic.

### P0 — E2E Kafka producer was not admitted by the explicit egress policy

File:
- `scripts/produce-synthetic-transactions.sh`

The deny-by-default model permits Kafka clients through the label:

`edl.network/kafka-client=true`

The E2E producer did not carry it.

Fix:
- add the required label to the pod created by the producer script.

### P0 — Spark I6 Docker build context mismatch

Files:
- `data-platform/spark/openshift/buildconfig.yaml`
- `data-platform/spark/image/Dockerfile`

BuildConfig context:
`data-platform/spark`

The Dockerfile previously copied:
`data-platform/spark/jobs/`

That path is outside the effective build-context-relative path.

Fix:
`COPY jobs/ /opt/spark/work-dir/jobs/`

### P0 — Jupyter PVC hid the image-baked examples

Files:
- `data-platform/jupyter/image/Dockerfile`
- `data-platform/jupyter/openshift/deployment.yaml`
- `scripts/test-jupyter-trino.sh`
- `scripts/test-jupyter-lakehouse.sh`

The image copied samples into `/home/jovyan/work`, while the Deployment mounts the workspace PVC on the same path.

Fix:
- immutable examples moved to `/opt/edl/examples`;
- the PVC remains only at `/home/jovyan/work`;
- smoke tests use the immutable example path.

### P0/P1 — Trino chart naming contract did not match clients

Files:
- `data-platform/trino/values-crc.yaml`
- Jupyter/LLD clients expecting `edl-trino.edl-data.svc`

Verified against official `trinodb/charts` chart 1.42.2.

The chart helper creates `edl-trino-trino` for release `edl-trino` unless a fullname override is provided.

Fix:
`fullnameOverride: edl-trino`

### P0/P1 — Trino coordinator memory-per-node inherited an unsafe CRC default

The official chart 1.42.2 defaults `coordinator.config.query.maxMemoryPerNode` to `1GB`.

The CRC coordinator heap is configured to `512M`.

Fix:
- explicit coordinator `maxMemoryPerNode: 256MB`;
- worker remains explicit at `256MB`.

### P1 — Legacy NetworkPolicy test could produce a false PASS

File:
- `scripts/test-networkpolicy.sh`

Before:
- denied-client execution/wait errors were ignored with `|| true`.

Fix:
- the test now requires the denied client to terminate in `Failed`;
- a `Succeeded` denied client is an immediate failure;
- explicit allow must still succeed.

## Previously reported findings not confirmed in this repository

### Argo CD unresolved variables

Not confirmed.

The current Application manifests under `gitops/apps/` use explicit:
- `repoURL`;
- `targetRevision`;
- paths;
- destinations.

The static contract now rejects unresolved shell-style `${...}` placeholders inside `gitops/apps`.

### Versioned OAuth / Keycloak secrets

No hard-coded OAuth/Keycloak secret was confirmed in this repository during this audit.

Known runtime credentials are generated/read through:
- Kubernetes Secrets;
- runtime environment variables;
- documented Vault/OIDC patterns.

This statement applies only to this repository and is not a claim about every repository in the account.

## CI hardening

Added:
- `tests/static/contracts.sh`;
- cross-component contract checks;
- Trino Helm 1.42.2 render in CI;
- stable Trino service-name assertion;
- Trino memory assertion;
- lakehouse catalog render assertion;
- obvious credential/private-key pattern check.

## Runtime boundary

No:
- `oc apply`;
- `kubectl apply`;
- Helm install against CRC;
- Operator installation;
- Kafka/Spark/Trino/Jupyter runtime;
- chaos test

was executed as part of this audit.

I1-I12 remain IMPLEMENTED / RUNTIME VALIDATION PENDING until real evidence exists.
