#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tests=(
  "00-preflight.sh"
  "10-dns.sh"
  "20-pvc.sh"
  "30-rbac.sh"
  "40-networkpolicy.sh"
  "50-exposure.sh"
)

for t in "${tests[@]}"; do
  echo
  echo "============================================================"
  echo "RUNNING I1 TEST: $t"
  echo "============================================================"
  bash "$DIR/$t"
done

echo
echo "[PASS] I1 executable test suite completed."
echo "Run 'bash tests/i1/cleanup.sh' when evidence capture is complete."
