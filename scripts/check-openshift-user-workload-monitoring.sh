#!/usr/bin/env bash
set -euo pipefail

command -v oc >/dev/null 2>&1 || {
  echo "[FAIL] oc is required"
  exit 1
}

config="$(oc -n openshift-monitoring get configmap cluster-monitoring-config -o jsonpath='{.data.config\.yaml}' 2>/dev/null || true)"

if ! printf '%s\n' "$config" | grep -Eq 'enableUserWorkload:[[:space:]]*true'; then
  echo "[FAIL] OpenShift User Workload Monitoring is not confirmed enabled."
  echo "A cluster-admin should set enableUserWorkload: true in openshift-monitoring/cluster-monitoring-config."
  exit 1
fi

for name in prometheus-operator prometheus-user-workload thanos-ruler-user-workload; do
  if ! oc -n openshift-user-workload-monitoring get pods --no-headers 2>/dev/null | grep -q "$name"; then
    echo "[FAIL] expected UWM component not found: $name"
    exit 1
  fi
done

for crd in servicemonitors.monitoring.coreos.com podmonitors.monitoring.coreos.com prometheusrules.monitoring.coreos.com; do
  oc get crd "$crd" >/dev/null 2>&1 || {
    echo "[FAIL] required monitoring CRD missing: $crd"
    exit 1
  }
done

echo "[PASS] OpenShift User Workload Monitoring is enabled and monitoring CRDs are available"
