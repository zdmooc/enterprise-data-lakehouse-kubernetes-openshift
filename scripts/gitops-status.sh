#!/usr/bin/env bash
set -euo pipefail

if command -v oc >/dev/null 2>&1 && oc api-resources 2>/dev/null | grep -q '^routes[[:space:]]'; then
  CLI=oc
  ARGO_NS=openshift-gitops
else
  CLI=kubectl
  ARGO_NS=argocd
fi

"$CLI" get ns "$ARGO_NS" >/dev/null 2>&1 || {
  echo "[FAIL] Argo CD namespace $ARGO_NS not found"
  exit 1
}

"$CLI" get crd applications.argoproj.io >/dev/null 2>&1 || {
  echo "[FAIL] Application CRD not found"
  exit 1
}

echo "=== AppProject ==="
"$CLI" -n "$ARGO_NS" get appproject enterprise-data-lakehouse 2>/dev/null || true

echo
echo "=== Applications ==="
"$CLI" -n "$ARGO_NS" get applications.argoproj.io 2>/dev/null || true

echo
echo "=== Baseline ==="
"$CLI" -n "$ARGO_NS" get application edl-platform-baseline   -o custom-columns='NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,REVISION:.status.sync.revision' 2>/dev/null || true

echo
echo "[INFO] read-only status check completed"
