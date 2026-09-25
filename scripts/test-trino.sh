#!/usr/bin/env bash
set -euo pipefail

if command -v oc >/dev/null 2>&1; then CLI=oc; else CLI=kubectl; fi
NS="${TRINO_NAMESPACE:-edl-data}"

coord=$("$CLI" -n "$NS" get pods   -l app.kubernetes.io/name=trino,app.kubernetes.io/component=coordinator   -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)

if [ -z "$coord" ]; then
  echo "[FAIL] Trino coordinator pod not found"
  exit 1
fi

"$CLI" -n "$NS" wait --for=condition=Ready "pod/$coord" --timeout=300s >/dev/null

query='SELECT count(*) AS customer_count FROM tpch.tiny.customer'
echo "[INFO] query: $query"

out=$("$CLI" -n "$NS" exec "$coord" -- trino --execute "$query" --output-format TSV_HEADER 2>&1) || {
  printf '%s\n' "$out"
  echo "[FAIL] Trino query failed"
  exit 1
}

printf '%s\n' "$out"

printf '%s\n' "$out" | grep -q '1500' || {
  echo "[FAIL] expected TPCH tiny customer count 1500"
  exit 1
}

echo "[PASS] Trino coordinator/worker SQL smoke test succeeded"
