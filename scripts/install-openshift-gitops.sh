#!/usr/bin/env bash
set -euo pipefail

command -v oc >/dev/null 2>&1 || { echo "[FAIL] oc is required"; exit 1; }

oc whoami >/dev/null 2>&1 || { echo "[FAIL] not logged into OpenShift"; exit 1; }

if ! oc api-resources | grep -q '^subscriptions[[:space:]]'; then
  echo "[FAIL] OLM Subscription API is unavailable"
  exit 1
fi

if oc get packagemanifest openshift-gitops-operator -n openshift-marketplace >/dev/null 2>&1; then
  channels="$(oc get packagemanifest openshift-gitops-operator -n openshift-marketplace -o jsonpath='{range .status.channels[*]}{.name}{"\n"}{end}' 2>/dev/null || true)"
  if ! printf '%s\n' "$channels" | grep -qx 'stable'; then
    echo "[FAIL] stable channel is not advertised by the current cluster catalog"
    echo "Available channels:"
    printf '%s\n' "$channels"
    exit 1
  fi
else
  echo "[WARN] PackageManifest was not readable; subscription will be applied but must be verified."
fi

oc apply -f gitops/bootstrap/openshift/namespace.yaml
oc apply -f gitops/bootstrap/openshift/operatorgroup.yaml
oc apply -f gitops/bootstrap/openshift/subscription.yaml

echo "[INFO] waiting for OpenShift GitOps CRDs"
for i in $(seq 1 60); do
  if oc get crd applications.argoproj.io >/dev/null 2>&1 &&      oc get crd appprojects.argoproj.io >/dev/null 2>&1; then
    echo "[PASS] Argo CD CRDs available"
    exit 0
  fi
  sleep 5
done

echo "[FAIL] Argo CD CRDs did not become available in time"
exit 1
