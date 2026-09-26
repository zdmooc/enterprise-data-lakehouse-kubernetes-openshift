#!/usr/bin/env bash
set -euo pipefail
command -v oc >/dev/null 2>&1 || { echo "[FAIL] oc required"; exit 1; }
[ "${CONFIRM_JUPYTER_RESTART:-}" = "yes" ] || {
  echo "[FAIL] set CONFIRM_JUPYTER_RESTART=yes to test Jupyter pod recreation"
  exit 1
}

NS=edl-data
pod="$(oc -n "$NS" get pod -l app=edl-jupyter -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
[ -n "$pod" ] || { echo "[FAIL] Jupyter pod not found"; exit 1; }

marker="pvc-persist-$(date -u +%Y%m%dT%H%M%SZ)"
oc -n "$NS" exec "$pod" -- sh -c "printf '%s' '$marker' > /home/jovyan/work/.persistence-proof"
oc -n "$NS" delete pod "$pod" --wait=false >/dev/null
oc -n "$NS" rollout status deployment/edl-jupyter --timeout=300s

newpod="$(oc -n "$NS" get pod -l app=edl-jupyter -o jsonpath='{.items[0].metadata.name}')"
observed="$(oc -n "$NS" exec "$newpod" -- cat /home/jovyan/work/.persistence-proof)"
[ "$observed" = "$marker" ] || { echo "[FAIL] workspace marker not preserved"; exit 1; }
echo "[PASS] Jupyter workspace survived pod recreation"
