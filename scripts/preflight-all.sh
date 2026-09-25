#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for s in preflight-cluster.sh test-dns.sh test-pvc.sh test-rbac.sh test-networkpolicy.sh; do
  echo "=== $s ==="
  bash "$ROOT/scripts/$s"
  echo
done
echo "[PASS] complete cluster preflight suite passed"
