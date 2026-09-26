#!/usr/bin/env bash
set -euo pipefail
command -v oc >/dev/null 2>&1 || { echo "[FAIL] oc required"; exit 1; }

oc get ns edl-data >/dev/null 2>&1 || { echo "[FAIL] apply I2 first"; exit 1; }
oc apply -f data-platform/spark/openshift/buildconfig.yaml
oc -n edl-data start-build edl-spark --follow --wait

oc -n edl-data delete job edl-transactions-submit --ignore-not-found=true --wait=true
oc apply -f data-platform/spark/openshift/transactions-submit.yaml
oc -n edl-data wait --for=condition=complete job/edl-transactions-submit --timeout=600s || {
  oc -n edl-data logs job/edl-transactions-submit || true
  exit 1
}

driver="$(oc -n edl-data get pods -l spark-app-name=edl-transactions-aggregate -o jsonpath='{.items[-1:].metadata.name}' 2>/dev/null || true)"
[ -n "$driver" ] || { echo "[FAIL] Spark transaction driver not found"; exit 1; }

logs="$(oc -n edl-data logs "$driver" 2>/dev/null || true)"
printf '%s\n' "$logs"
printf '%s\n' "$logs" | grep -q 'EDL_AGGREGATE_RESULT' || {
  echo "[FAIL] aggregate marker missing"
  exit 1
}
echo "[PASS] Spark synthetic transaction transformation completed"
