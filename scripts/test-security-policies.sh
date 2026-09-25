#!/usr/bin/env bash
set -euo pipefail

if command -v oc >/dev/null 2>&1; then CLI=oc; else CLI=kubectl; fi

echo "[INFO] negative test: latest image must be denied"
if "$CLI" create --dry-run=server -f security/kyverno/tests/pod-latest-denied.yaml >/tmp/edl-policy-negative.out 2>&1; then
  cat /tmp/edl-policy-negative.out
  echo "[FAIL] latest-tag pod was accepted"
  exit 1
else
  cat /tmp/edl-policy-negative.out
fi

echo "[INFO] positive test: versioned image should pass admission"
"$CLI" create --dry-run=server -f security/kyverno/tests/pod-versioned-allowed.yaml >/tmp/edl-policy-positive.out 2>&1 || {
  cat /tmp/edl-policy-positive.out
  echo "[FAIL] versioned pod did not pass admission"
  exit 1
}
cat /tmp/edl-policy-positive.out

echo "[PASS] Kyverno deny/allow admission tests succeeded"
