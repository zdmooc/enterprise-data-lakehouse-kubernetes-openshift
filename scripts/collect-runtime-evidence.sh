#!/usr/bin/env bash
set -euo pipefail

if command -v oc >/dev/null 2>&1; then CLI=oc; else CLI=kubectl; fi

ts="$(date -u +%Y%m%dT%H%M%SZ)"
out="${1:-evidence/raw/$ts}"
mkdir -p "$out"

capture() {
  local name="$1"
  shift
  {
    echo "# COMMAND: $*"
    "$@"
  } >"$out/$name.txt" 2>&1 || true
}

capture version "$CLI" version
capture nodes "$CLI" get nodes -o wide
capture namespaces "$CLI" get ns
capture storageclasses "$CLI" get storageclass
capture edl-pods "$CLI" -n edl-data get pods -o wide
capture edl-workloads "$CLI" -n edl-data get deployment,statefulset,job
capture edl-pvc "$CLI" -n edl-data get pvc
capture edl-services "$CLI" -n edl-data get service
capture edl-networkpolicies "$CLI" -n edl-data get networkpolicy
capture edl-events "$CLI" -n edl-data get events --sort-by=.lastTimestamp

if "$CLI" get crd applications.argoproj.io >/dev/null 2>&1; then
  capture argocd-apps "$CLI" -n openshift-gitops get application
fi

if "$CLI" get crd kafkas.kafka.strimzi.io >/dev/null 2>&1; then
  capture kafka-resources "$CLI" -n edl-data get kafka,kafkanodepool,kafkatopic
  capture kafka-status "$CLI" -n edl-data get kafka edl-kafka -o yaml
fi

if "$CLI" get crd podmonitors.monitoring.coreos.com >/dev/null 2>&1; then
  capture monitoring-resources "$CLI" -n edl-data get podmonitor,servicemonitor,prometheusrule
fi

# Intentionally never export Secret objects.
echo "[PASS] evidence collected in $out"
echo "[INFO] Secret resources were intentionally excluded."
