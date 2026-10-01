#!/usr/bin/env bash
set -euo pipefail
if command -v oc >/dev/null 2>&1; then CLI=oc; else CLI=kubectl; fi
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
"$CLI" get crd namespacedvalidatingpolicies.policies.kyverno.io >/dev/null
"$CLI" -n edl-data get namespacedvalidatingpolicy disallow-latest-images >/dev/null
"$CLI" create --dry-run=server -f security/kyverno/tests/pod-versioned-allowed.yaml >/dev/null
if "$CLI" create --dry-run=server -f security/kyverno/tests/pod-latest-denied.yaml >"$tmp" 2>&1; then
  echo "[FAIL] latest-tag pod was accepted"
  exit 1
fi
if ! grep -q 'disallow-latest-images' "$tmp"; then
  cat "$tmp"
  echo "[FAIL] rejection did not identify the expected image policy"
  exit 1
fi
echo "[PASS] versioned pod accepted and latest tag rejected by the expected policy"
