#!/usr/bin/env bash
set -euo pipefail

command -v oc >/dev/null 2>&1 || { echo "[FAIL] oc required"; exit 1; }

bash scripts/check-openshift-user-workload-monitoring.sh

oc apply -k observability/openshift

echo "[PASS] Data Platform PodMonitor, ServiceMonitors and PrometheusRules applied"
