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
