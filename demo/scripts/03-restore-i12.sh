#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

[ "${CONFIRM_DEMO_RECOVERY:-}" = "yes" ] || {
  echo "[STOP] Re-run with CONFIRM_DEMO_RECOVERY=yes"
  exit 2
}

[ "$(kubectl config current-context)" = "kind-edl-lab" ] || { echo "[FAIL] wrong context"; exit 1; }

SNAPSHOT="evidence/kind-edl-lab/20260928T112119Z"
for file in "$SNAPSHOT/i12/transaction.json" "$SNAPSHOT/i12/polaris-after.json"; do
  [ -f "$file" ] || { echo "[FAIL] missing $file"; exit 1; }
done

mkdir -p .audit/kind
printf '%s
' "$SNAPSHOT" > .audit/kind/evidence-dir

source scripts/kind/common.sh
py scripts/kind/restore-polaris-i12.py

echo "===== TRINO SIX ROWS ====="
k -n edl-data exec deployment/edl-trino-coordinator --   trino --server http://localhost:8080 --user edl --execute   'SELECT eventId, transactionId, amount, status FROM polaris.analytics.transactions ORDER BY eventId'

echo "===== JUPYTER -> TRINO ASSERTION ====="
k -n edl-data exec deployment/edl-jupyter -- python -c '
import os,trino
c=trino.dbapi.connect(host=os.environ["TRINO_HOST"],port=8080,user="data-analyst",catalog="polaris",schema="analytics")
q=c.cursor(); q.execute("SELECT eventId FROM transactions ORDER BY eventId")
rows=[r[0] for r in q.fetchall()]
expected={"E2E-I12-20260930T051236Z-a0adb24c8c95", *[f"evt-{i:04d}" for i in range(1,6)]}
assert len(rows)==6 and set(rows)==expected, rows
print("[PASS] Jupyter -> Trino -> Iceberg: six retained I12 rows")
'

echo "[PASS] I12 recovery/data verification complete"
