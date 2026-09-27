# Static Contract Tests

These tests validate cross-component assumptions that simple YAML/Kustomize rendering cannot catch.

Covered contracts:
- Kafka smoke traffic is isolated from the JSON E2E topic;
- the E2E producer carries the label required by the deny-by-default egress policy;
- Spark Dockerfile paths match its OpenShift BuildConfig context;
- Jupyter immutable examples are not hidden by the workspace PVC;
- Trino uses the stable service name expected by Jupyter and scripts;
- Trino CRC memory-per-node limits are explicit;
- Argo CD Application manifests do not contain unresolved shell-style placeholders;
- obvious private-key/AWS-key patterns are rejected;
- the legacy NetworkPolicy test fails closed.

This is static validation only. It does not replace CRC runtime evidence.
