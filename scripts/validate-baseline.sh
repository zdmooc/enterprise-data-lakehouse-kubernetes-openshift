#!/usr/bin/env bash
set -euo pipefail

if command -v oc >/dev/null 2>&1; then CLI=oc; else CLI=kubectl; fi

fail=0
ok(){ echo "[PASS] $*"; }
bad(){ echo "[FAIL] $*" >&2; fail=1; }

for ns in edl-platform edl-data edl-observability; do
  "$CLI" get ns "$ns" >/dev/null 2>&1 && ok "namespace $ns exists" || bad "namespace $ns missing"
done

"$CLI" -n edl-data get resourcequota edl-data-quota >/dev/null 2>&1   && ok "data ResourceQuota exists" || bad "data ResourceQuota missing"

"$CLI" -n edl-data get limitrange default-container-limits >/dev/null 2>&1   && ok "data LimitRange exists" || bad "data LimitRange missing"

"$CLI" -n edl-data get networkpolicy default-deny-all >/dev/null 2>&1   && ok "default-deny NetworkPolicy exists" || bad "default-deny NetworkPolicy missing"

"$CLI" -n edl-data get networkpolicy allow-dns-egress >/dev/null 2>&1   && ok "DNS egress policy exists" || bad "DNS egress policy missing"

SA="system:serviceaccount:edl-data:data-workload"

pods=$("$CLI" auth can-i list pods -n edl-data --as="$SA" 2>/dev/null || true)
secrets=$("$CLI" auth can-i list secrets -n edl-data --as="$SA" 2>/dev/null || true)
nodes=$("$CLI" auth can-i list nodes --as="$SA" 2>/dev/null || true)

[ "$pods" = "yes" ] && ok "data-workload can list pods" || bad "data-workload cannot list pods"
[ "$secrets" = "no" ] && ok "data-workload cannot list secrets" || bad "data-workload can list secrets"
[ "$nodes" = "no" ] && ok "data-workload cannot list nodes" || bad "data-workload can list nodes"

if [ "$fail" -eq 0 ]; then
  echo "[PASS] platform baseline validation completed"
else
  echo "[FAIL] platform baseline validation found errors"
  exit 1
fi
