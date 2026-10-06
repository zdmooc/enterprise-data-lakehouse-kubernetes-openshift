#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

[ "$(kubectl config current-context)" = "kind-edl-lab" ] || {
  echo "[FAIL] expected kind-edl-lab"
  exit 1
}

echo "This runs the Spark smoke/Pi job only; it does not mutate Lakehouse business data."
bash scripts/kind/spark.sh smoke

echo
echo "Spark History Server should discover the event log within a few seconds."
echo "Open: http://127.0.0.1:18083"
