#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "[FAIL] $*" >&2
  exit 1
}

grep -q 'TOPIC="transactions.smoke"' scripts/test-kafka.sh || fail "Kafka smoke test must use transactions.smoke"
grep -q 'name: transactions.smoke' data-platform/kafka/base/topics.yaml || fail "transactions.smoke KafkaTopic is missing"
if grep -q 'TOPIC="transactions.raw"' scripts/test-kafka.sh; then
  fail "Kafka smoke test must not write plain text to transactions.raw"
fi

grep -q -- "--labels='edl.network/kafka-client=true'" scripts/produce-synthetic-transactions.sh   || fail "E2E producer is missing the Kafka client NetworkPolicy label"

grep -q '^COPY jobs/ /opt/spark/work-dir/jobs/$' data-platform/spark/image/Dockerfile   || fail "Spark Docker COPY must be relative to contextDir=data-platform/spark"

grep -q '^COPY sample/ /opt/edl/examples/$' data-platform/jupyter/image/Dockerfile   || fail "Jupyter sample code must live outside the workspace PVC mount"
grep -q '/opt/edl/examples/trino_query.py' scripts/test-jupyter-trino.sh   || fail "Jupyter Trino smoke test points to the wrong path"
grep -q '/opt/edl/examples/trino_lakehouse_query.py' scripts/test-jupyter-lakehouse.sh   || fail "Jupyter Lakehouse test points to the wrong path"

grep -q '^fullnameOverride: edl-trino$' data-platform/trino/values-crc.yaml   || fail "Trino fullnameOverride must keep the coordinator service at edl-trino"
count="$(grep -c 'maxMemoryPerNode: "256MB"' data-platform/trino/values-crc.yaml || true)"
[ "$count" -ge 2 ] || fail "Trino coordinator and worker memory-per-node limits must be explicit for CRC"

if grep -R -nE '\$\{[^}]+\}' gitops/apps; then
  fail "unresolved shell-style placeholder found in Argo CD Applications"
fi

if grep -R -nE 'AKIA[0-9A-Z]{16}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'   . --exclude-dir=.git; then
  fail "obvious credential/private-key pattern found"
fi

grep -q 'default-deny NetworkPolicy allowed denied-client' scripts/test-networkpolicy.sh   || fail "legacy NetworkPolicy test is not fail-closed"

echo "[PASS] static cross-component contracts validated"
