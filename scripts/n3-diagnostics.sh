#!/usr/bin/env bash
set -euo pipefail
CLI=kubectl
command -v oc >/dev/null 2>&1 && CLI=oc
NS="${NAMESPACE:-edl-data}"

echo "=== cluster ==="
"$CLI" version || true
"$CLI" get nodes -o wide || true

echo "=== namespace $NS ==="
"$CLI" -n "$NS" get pods -o wide || true
"$CLI" -n "$NS" get deployment,statefulset,job || true
"$CLI" -n "$NS" get svc,endpoints || true
"$CLI" -n "$NS" get pvc || true
"$CLI" -n "$NS" get networkpolicy || true
"$CLI" -n "$NS" get events --sort-by=.lastTimestamp || true

if "$CLI" get crd applications.argoproj.io >/dev/null 2>&1; then
  argo_ns=argocd
  "$CLI" get ns openshift-gitops >/dev/null 2>&1 && argo_ns=openshift-gitops
  "$CLI" -n "$argo_ns" get application || true
fi

if "$CLI" get crd kafkas.kafka.strimzi.io >/dev/null 2>&1; then
  "$CLI" -n "$NS" get kafka,kafkanodepool,kafkatopic || true
fi

echo "[INFO] diagnostics complete; Secret objects were intentionally not exported"
