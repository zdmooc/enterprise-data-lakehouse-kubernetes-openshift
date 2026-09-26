#!/usr/bin/env bash
set -euo pipefail
command -v oc >/dev/null 2>&1 || { echo "[FAIL] oc required"; exit 1; }

pod="$(oc -n edl-data get pod -l app=edl-jupyter -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
[ -n "$pod" ] || { echo "[FAIL] Jupyter pod not found"; exit 1; }

out="$(oc -n edl-data exec "$pod" -- python /home/jovyan/work/trino_lakehouse_query.py 2>&1)" || {
  printf '%s\n' "$out"
  exit 1
}
printf '%s\n' "$out"
printf '%s\n' "$out" | grep -q 'EDL_JUPYTER_LAKEHOUSE_ROWS=' || {
  echo "[FAIL] lakehouse result marker missing"
  exit 1
}
echo "[PASS] Jupyter queried Iceberg data through Trino"
