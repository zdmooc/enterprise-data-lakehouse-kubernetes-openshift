#!/usr/bin/env bash
set -euo pipefail
CLI=kubectl
command -v oc >/dev/null 2>&1 && CLI=oc
NS=edl-data
SA="system:serviceaccount:$NS:data-workload"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

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
  local reason="$3"
  if "$CLI" create --dry-run=server -f "$file" >"$tmp" 2>&1; then
    echo "[FAIL] $description: request was accepted"
    exit 1
  fi
  grep -Eiq "$reason" "$tmp" && grep -Eiq 'forbidden|violates PodSecurity|security context constraint' "$tmp" || {
    cat "$tmp"
    echo "[FAIL] request failed without the expected admission rejection"
    exit 1
  }
  echo "[PASS] $description"
}

expect_no "service account cannot read Secrets" "$CLI" auth can-i get secrets -n "$NS" --as="$SA"
expect_no "service account cannot delete Pods" "$CLI" auth can-i delete pods -n "$NS" --as="$SA"

bash scripts/test-security-policies.sh

expect_rejected "privileged workload rejected" security/tests/privileged-pod-denied.yaml 'privileged'
expect_rejected "hostNetwork workload rejected" security/tests/hostnetwork-pod-denied.yaml 'hostNetwork|host namespaces'

echo "[PASS] five negative security cases validated"
