#!/usr/bin/env bash
set -euo pipefail

command -v helm >/dev/null 2>&1 || { echo "[FAIL] helm required"; exit 1; }

if command -v oc >/dev/null 2>&1; then CLI=oc; else CLI=kubectl; fi

"$CLI" -n edl-data get secret polaris-client >/dev/null 2>&1 || {
  echo "[FAIL] polaris-client secret missing; install Polaris first"
  exit 1
}

helm repo add trino https://trinodb.github.io/charts/ --force-update >/dev/null
helm repo update >/dev/null

helm upgrade --install edl-trino trino/trino   --version "${TRINO_CHART_VERSION:-1.42.2}"   --namespace edl-data   -f data-platform/trino/values-crc.yaml   -f data-platform/trino/values-lakehouse.yaml   --wait   --timeout 10m

echo "[PASS] Trino Polaris/Iceberg catalog enabled"
