#!/usr/bin/env bash
set -euo pipefail

command -v oc >/dev/null 2>&1 || {
  echo "[FAIL] oc is required for the CRC profile"
  exit 1
}

oc get ns edl-data >/dev/null 2>&1 || {
  echo "[FAIL] edl-data namespace missing; apply I2 baseline first"
  exit 1
}

oc apply -k data-platform/spark/profiles/crc

echo "[INFO] waiting for spark-submit Job"
oc -n edl-data wait --for=condition=complete job/spark-pi-submit --timeout=600s || {
  oc -n edl-data logs job/spark-pi-submit || true
  oc -n edl-data get pods -l spark-role=driver -o wide || true
  exit 1
}

oc -n edl-data logs job/spark-pi-submit || true

driver="$(oc -n edl-data get pods -l spark-role=driver -o jsonpath='{.items[-1:].metadata.name}' 2>/dev/null || true)"
if [ -z "$driver" ]; then
  echo "[FAIL] Spark driver pod not found"
  exit 1
fi

logs="$(oc -n edl-data logs "$driver" 2>/dev/null || true)"
printf '%s\n' "$logs"

printf '%s\n' "$logs" | grep -q 'Pi is roughly' || {
  echo "[FAIL] Spark Pi result not found in driver logs"
  exit 1
}

echo "[PASS] Spark 4.2.0 Kubernetes cluster-mode smoke test succeeded"
