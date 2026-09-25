#!/usr/bin/env bash
set -euo pipefail

command -v oc >/dev/null 2>&1 || { echo "[FAIL] oc required"; exit 1; }

pod="$(oc -n edl-data get pod -l app=edl-jupyter -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"

if [ -z "$pod" ]; then
  echo "[FAIL] Jupyter pod not found"
  exit 1
fi

out="$(oc -n edl-data exec "$pod" -- python /home/jovyan/work/trino_query.py 2>&1)" || {
  printf '%s\n' "$out"
  echo "[FAIL] Jupyter -> Trino query failed"
  exit 1
}

printf '%s\n' "$out"
echo "[PASS] Jupyter Python client queried Trino"
