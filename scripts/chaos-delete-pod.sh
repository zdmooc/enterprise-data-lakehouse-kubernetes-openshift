#!/usr/bin/env bash
set -euo pipefail

if [ "${CONFIRM_CHAOS:-}" != "yes" ]; then
  echo "[FAIL] set CONFIRM_CHAOS=yes to run a pod deletion test"
  exit 1
fi

if command -v oc >/dev/null 2>&1; then CLI=oc; else CLI=kubectl; fi

NS="${NAMESPACE:-edl-data}"
SELECTOR="${SELECTOR:-}"

[ "$NS" = "edl-data" ] || {
  echo "[FAIL] this public lab script is restricted to namespace edl-data"
  exit 1
}

[ -n "$SELECTOR" ] || {
  echo "[FAIL] set SELECTOR, for example SELECTOR='app=edl-jupyter'"
  exit 1
}

pod=$("$CLI" -n "$NS" get pod -l "$SELECTOR" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
[ -n "$pod" ] || {
  echo "[FAIL] no pod matches selector: $SELECTOR"
  exit 1
}

owner=$("$CLI" -n "$NS" get pod "$pod" -o jsonpath='{.metadata.ownerReferences[0].kind}/{.metadata.ownerReferences[0].name}' 2>/dev/null || true)
echo "[INFO] deleting pod=$pod owner=${owner:-unknown}"

before="$(date +%s)"
"$CLI" -n "$NS" delete pod "$pod" --wait=false

echo "[INFO] waiting for replacement Ready pod matching $SELECTOR"
for i in $(seq 1 120); do
  replacement=$("$CLI" -n "$NS" get pod -l "$SELECTOR"     --field-selector=status.phase=Running     -o jsonpath='{range .items[*]}{.metadata.name}{" "}{end}' 2>/dev/null || true)
  if [ -n "$replacement" ] && ! printf '%s\n' "$replacement" | grep -qw "$pod"; then
    "$CLI" -n "$NS" wait pod -l "$SELECTOR" --for=condition=Ready --timeout=120s >/dev/null || true
    after="$(date +%s)"
    echo "[PASS] replacement observed after $((after-before)) seconds: $replacement"
    exit 0
  fi
  sleep 2
done

echo "[FAIL] no Ready replacement observed"
exit 1
