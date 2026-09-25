#!/usr/bin/env bash
set -euo pipefail

if command -v oc >/dev/null 2>&1 && oc api-resources 2>/dev/null | grep -q '^routes[[:space:]]'; then
  CLI=oc
  CONTROL_OVERLAY=gitops/control/overlays/openshift
  APP=gitops/apps/openshift-crc/platform-baseline.yaml
  ARGO_NS=openshift-gitops
else
  CLI=kubectl
  CONTROL_OVERLAY=gitops/control/overlays/kubernetes
  APP=gitops/apps/kubernetes/platform-baseline.yaml
  ARGO_NS=argocd
fi

"$CLI" get crd applications.argoproj.io >/dev/null 2>&1 || {
  echo "[FAIL] Argo CD Application CRD not found. Install Argo CD/OpenShift GitOps first."
  exit 1
}

"$CLI" get ns "$ARGO_NS" >/dev/null 2>&1 || {
  echo "[FAIL] Argo CD namespace $ARGO_NS not found."
  exit 1
}

"$CLI" apply -k "$CONTROL_OVERLAY"
"$CLI" apply -f "$APP"

echo "[INFO] waiting for Application status"
for i in $(seq 1 60); do
  sync=$("$CLI" -n "$ARGO_NS" get application edl-platform-baseline -o jsonpath='{.status.sync.status}' 2>/dev/null || true)
  health=$("$CLI" -n "$ARGO_NS" get application edl-platform-baseline -o jsonpath='{.status.health.status}' 2>/dev/null || true)
  echo "[INFO] sync=${sync:-unknown} health=${health:-unknown}"
  if [ "$sync" = "Synced" ] && { [ "$health" = "Healthy" ] || [ "$health" = "Missing" ]; }; then
    echo "[PASS] GitOps baseline application is reconciled"
    exit 0
  fi
  sleep 5
done

echo "[FAIL] GitOps baseline did not reach expected status"
"$CLI" -n "$ARGO_NS" get application edl-platform-baseline -o yaml || true
exit 1
