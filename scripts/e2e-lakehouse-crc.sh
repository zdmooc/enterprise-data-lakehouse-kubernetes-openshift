#!/usr/bin/env bash
set -euo pipefail

[ "${CONFIRM_EDL_E2E:-}" = "yes" ] || {
  echo "[FAIL] set CONFIRM_EDL_E2E=yes to run the EDL end-to-end CRC scenario"
  echo "[INFO] the script is restricted to edl-* resources and does not touch other POC namespaces"
  exit 1
}

command -v oc >/dev/null 2>&1 || { echo "[FAIL] oc required"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "[FAIL] helm required"; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "[FAIL] aws CLI required"; exit 1; }

required=(S3_ENDPOINT S3_BUCKET AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY)
for v in "${required[@]}"; do
  [ -n "${!v:-}" ] || { echo "[FAIL] missing environment variable: $v"; exit 1; }
done

NS=edl-data
oc get ns "$NS" >/dev/null 2>&1 || {
  echo "[FAIL] $NS missing; runtime-validate/apply I2 first"
  exit 1
}

echo "=== I4 S3 ==="
bash scripts/verify-s3-layout.sh

echo "=== Data Product networking ==="
bash scripts/apply-data-networking.sh

echo "=== I5 Kafka ==="
oc get crd kafkas.kafka.strimzi.io >/dev/null 2>&1 || {
  echo "[FAIL] Strimzi is not installed; run scripts/install-strimzi.sh first"
  exit 1
}
bash scripts/deploy-kafka-crc.sh
bash scripts/test-kafka.sh
bash scripts/produce-synthetic-transactions.sh

echo "=== I12 Polaris catalog ==="
bash scripts/install-polaris-crc.sh
bash scripts/bootstrap-polaris-catalog.sh

echo "=== I12 Spark + Iceberg ==="
oc apply -f data-platform/spark/base/rbac.yaml
oc apply -f data-platform/lakehouse/openshift/buildconfig.yaml
oc -n "$NS" start-build edl-spark-lakehouse --follow --wait

oc -n "$NS" delete job edl-lakehouse-submit --ignore-not-found=true --wait=true >/dev/null 2>&1 || true
oc apply -f data-platform/lakehouse/openshift/spark-submit-job.yaml
oc -n "$NS" wait --for=condition=complete job/edl-lakehouse-submit --timeout=900s || {
  oc -n "$NS" logs job/edl-lakehouse-submit || true
  exit 1
}

driver="$(oc -n "$NS" get pod -l spark-app-name=edl-transactions-lakehouse -o jsonpath='{.items[-1:].metadata.name}' 2>/dev/null || true)"
[ -n "$driver" ] || { echo "[FAIL] lakehouse Spark driver not found"; exit 1; }
spark_logs="$(oc -n "$NS" logs "$driver" 2>/dev/null || true)"
printf '%s\n' "$spark_logs"
printf '%s\n' "$spark_logs" | grep -q 'EDL_EVENT_COUNT=' || {
  echo "[FAIL] Spark/Iceberg event count marker missing"
  exit 1
}

echo "=== I7 Trino + Iceberg REST catalog ==="
bash scripts/enable-trino-lakehouse.sh

coord="$(oc -n "$NS" get pod   -l app.kubernetes.io/name=trino,app.kubernetes.io/component=coordinator   -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
[ -n "$coord" ] || { echo "[FAIL] Trino coordinator not found"; exit 1; }

trino_out="$(oc -n "$NS" exec "$coord" -- trino   --execute 'SELECT count(*) AS event_count FROM polaris.analytics.transactions'   --output-format TSV_HEADER 2>&1)" || {
  printf '%s\n' "$trino_out"
  exit 1
}
printf '%s\n' "$trino_out"

count="$(printf '%s\n' "$trino_out" | awk 'NF && $1 ~ /^[0-9]+$/ {print $1}' | tail -1)"
[ -n "$count" ] && [ "$count" -ge 5 ] || {
  echo "[FAIL] expected at least 5 lakehouse rows, observed: ${count:-unknown}"
  exit 1
}

echo "=== I8 Jupyter ==="
bash scripts/deploy-jupyter-crc.sh
bash scripts/test-jupyter-lakehouse.sh

echo "=== I10 Observability status ==="
if oc get crd servicemonitors.monitoring.coreos.com >/dev/null 2>&1; then
  bash scripts/apply-observability-openshift.sh || true
  bash scripts/test-observability-openshift.sh || true
else
  echo "[WARN] Prometheus Operator CRDs unavailable; observability runtime remains pending"
fi

echo "=== I3 GitOps status ==="
bash scripts/gitops-status.sh || true

echo "=== Evidence snapshot ==="
bash scripts/collect-runtime-evidence.sh

echo "[PASS] EDL end-to-end CRC flow completed"
echo "[WARN] CRC single-node success is functional interoperability evidence, not HA evidence"
