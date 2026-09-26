#!/usr/bin/env bash
set -euo pipefail
CLI=kubectl
command -v oc >/dev/null 2>&1 && CLI=oc
NS=edl-data
SA="system:serviceaccount:$NS:data-workload"

expect_no() {
  local description="$1"
  shift
  result="$("$@" 2>/dev/null || true)"
  [ "$result" = "no" ] || { echo "[FAIL] $description: expected no, got $result"; exit 1; }
  echo "[PASS] $description"
}

expect_rejected() {
  local description="$1"
  local file="$2"
  if "$CLI" create --dry-run=server -f "$file" >/tmp/edl-security-negative.out 2>&1; then
    cat /tmp/edl-security-negative.out
    echo "[FAIL] $description: request was accepted"
    exit 1
  fi
  echo "[PASS] $description"
}

expect_no "service account cannot read Secrets" "$CLI" auth can-i get secrets -n "$NS" --as="$SA"
expect_no "service account cannot delete Pods" "$CLI" auth can-i delete pods -n "$NS" --as="$SA"

if "$CLI" get crd validatingpolicies.policies.kyverno.io >/dev/null 2>&1 ||    "$CLI" get crd clusterpolicies.kyverno.io >/dev/null 2>&1; then
  if "$CLI" create --dry-run=server -f security/kyverno/tests/pod-latest-denied.yaml >/tmp/edl-latest.out 2>&1; then
    cat /tmp/edl-latest.out
    echo "[FAIL] latest-tag workload accepted"
    exit 1
  fi
  echo "[PASS] latest-tag workload rejected"
else
  echo "[FAIL] Kyverno policy CRDs not found; install/apply I9 policies first"
  exit 1
fi

expect_rejected "privileged workload rejected" security/tests/privileged-pod-denied.yaml
expect_rejected "hostNetwork workload rejected" security/tests/hostnetwork-pod-denied.yaml

echo "[PASS] five negative security cases validated"
