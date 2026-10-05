#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

[ "$(kubectl config current-context)" = "kind-edl-lab" ] || { echo "[FAIL] expected kind-edl-lab"; exit 1; }

source scripts/kind/common.sh

echo "===== 1. PLATFORM HEALTH ====="
py scripts/kind/check-health.py
k get nodes -o wide

echo "===== 2. GITOPS ====="
k -n argocd get applications

echo "===== 3. DATA PLATFORM ====="
k -n edl-data get kafka edl-kafka
k -n edl-data get deployment edl-s3 edl-polaris edl-trino-coordinator edl-trino-worker edl-jupyter
k -n edl-data get pvc

echo "===== 4. I12 DATA THROUGH TRINO ====="
k -n edl-data exec deployment/edl-trino-coordinator --   trino --server http://localhost:8080 --user edl --execute   'SELECT eventId, transactionId, amount, status FROM polaris.analytics.transactions ORDER BY eventId'

echo "===== 5. JUPYTER -> TRINO ====="
k -n edl-data exec deployment/edl-jupyter -- python -c '
import os,trino
c=trino.dbapi.connect(host=os.environ["TRINO_HOST"],port=8080,user="data-analyst",catalog="polaris",schema="analytics")
q=c.cursor(); q.execute("SELECT eventId, amount, status FROM transactions ORDER BY eventId")
rows=q.fetchall()
assert len(rows)==6, rows
for row in rows: print(row)
print("[PASS] Jupyter -> Trino returned six retained rows")
'

echo "===== 6. SECURITY ====="
k get clusterpolicy 2>/dev/null || echo "[INFO] clusterpolicy resource not listed"
k -n edl-data get networkpolicy
k -n edl-data get role,rolebinding

echo "===== 7. OBSERVABILITY ====="
k -n edl-observability get pods
py - <<'PY'
import json, urllib.request
try:
    with urllib.request.urlopen("http://127.0.0.1:19090/api/v1/targets?state=active", timeout=3) as r:
        d=json.load(r)
    targets=d["data"]["activeTargets"]
    up=sum(1 for t in targets if t.get("health")=="up")
    print(f"PROMETHEUS_ACTIVE_TARGETS={len(targets)}")
    print(f"PROMETHEUS_TARGETS_UP={up}")
except Exception as exc:
    print("[INFO] Prometheus port-forward unavailable:", exc)
    print("[INFO] Run: bash demo/scripts/04-start-interfaces.sh")
PY

echo "===== 8. TRUTH BOUNDARY ====="
echo "Local three-node Kind functional proof."
echo "No claim of multi-host HA, DR, durable Polaris catalog or production readiness."

echo "[PASS] READ-ONLY DEMO COMPLETE"
