#!/usr/bin/env bash
set -euo pipefail

command -v helm >/dev/null 2>&1 || {
  echo "[FAIL] helm is required"
  exit 1
}

if command -v oc >/dev/null 2>&1; then CLI=oc; else CLI=kubectl; fi

CHART_VERSION="${TRINO_CHART_VERSION:-1.42.2}"
NS="${TRINO_NAMESPACE:-edl-data}"

"$CLI" get ns "$NS" >/dev/null 2>&1 || {
  echo "[FAIL] namespace $NS missing; apply I2 baseline first"
  exit 1
}

helm repo add trino https://trinodb.github.io/charts/ --force-update >/dev/null
helm repo update >/dev/null

echo "[INFO] installing Trino chart $CHART_VERSION"
helm upgrade --install edl-trino trino/trino   --version "$CHART_VERSION"   --namespace "$NS"   -f data-platform/trino/values-crc.yaml   --wait   --timeout 10m

"$CLI" -n "$NS" get pods -l app.kubernetes.io/name=trino -o wide
echo "[PASS] Trino Helm release reconciled"
