#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
guard
ready_nodes

[ "${CONFIRM_VISUALIZATION:-}" = "yes" ] || fail "re-run with CONFIRM_VISUALIZATION=yes"

echo "===== 1. RUSTFS WEB CONSOLE ====="
k apply -k data-platform/object-storage/profiles/kind
k -n edl-data rollout status deployment/edl-s3 --timeout=600s

echo "===== 2. POLARIS CORS + METADATA RECOVERY ====="
py scripts/kind/polaris.py secrets
h upgrade --install edl-polaris polaris --version 1.7.0 --namespace edl-data \
  --repo https://downloads.apache.org/polaris/helm-chart \
  --repository-config .audit/kind/repos.yaml --repository-cache .audit/kind/helm-cache \
  -f data-platform/catalog/polaris/values-kind.yaml --wait --timeout=10m

SNAPSHOT=evidence/kind-edl-lab/20260928T112119Z
test -f "$SNAPSHOT/i12/transaction.json" || fail "retained I12 transaction evidence missing"
test -f "$SNAPSHOT/i12/polaris-after.json" || fail "retained I12 Polaris evidence missing"
mkdir -p .audit/kind
printf '%s\n' "$SNAPSHOT" > .audit/kind/evidence-dir
py scripts/kind/restore-polaris-i12.py

echo "===== 3. REDPANDA CONSOLE IMAGE ====="
RP_IMAGE=docker.redpanda.com/redpandadata/console:v3.12.0
if ! docker image inspect "$RP_IMAGE" >/dev/null 2>&1; then
  docker pull "$RP_IMAGE"
fi
kind load docker-image "$RP_IMAGE" --name "$CLUSTER"

echo "===== 4. POLARIS CONSOLE IMAGE ====="
bash scripts/kind/build-polaris-console.sh

echo "===== 5. VISUALIZATION WORKLOADS ====="
docker image inspect edl-spark-lakehouse:kind-4.1.3-iceberg1.11 >/dev/null 2>&1 || \
  fail "Spark lakehouse image missing locally; run scripts/kind/build-spark.sh first"
kind load docker-image edl-spark-lakehouse:kind-4.1.3-iceberg1.11 --name "$CLUSTER"

k apply -k platform/kind/visualization
for d in edl-kafka-console edl-spark-history edl-polaris-console; do
  k -n edl-data rollout status deployment/"$d" --timeout=600s
done

echo "===== 6. JUPYTER ICEBERG EXPLORER ====="
JUPYTER_POD="$(k -n edl-data get pod -l app=edl-jupyter -o jsonpath='{.items[0].metadata.name}')"
test -n "$JUPYTER_POD" || fail "Jupyter pod not found"
k -n edl-data cp demo/notebooks/ICEBERG_EXPLORER.ipynb \
  "$JUPYTER_POD:/home/jovyan/work/ICEBERG_EXPLORER.ipynb"

echo "===== 7. GENERATE ONE SAFE SPARK HISTORY ENTRY ====="
bash scripts/kind/spark.sh smoke

echo "===== 8. FINAL STATUS ====="
k -n edl-data get deploy edl-kafka-console edl-spark-history edl-polaris-console
k -n edl-data get svc edl-kafka-console edl-spark-history edl-polaris-console edl-s3 edl-polaris edl-trino
k -n edl-data get pvc spark-event-logs edl-s3
py scripts/kind/check-health.py

echo
echo "[PASS] visual demo layer installed"
echo "[NEXT] Windows: powershell -ExecutionPolicy Bypass -File demo/scripts/04-start-interfaces-windows.ps1"
echo "[NEXT] Portable shell: bash demo/scripts/04-start-interfaces.sh"
