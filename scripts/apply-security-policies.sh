#!/usr/bin/env bash
set -euo pipefail

if command -v oc >/dev/null 2>&1; then CLI=oc; else CLI=kubectl; fi

"$CLI" get crd validatingpolicies.policies.kyverno.io >/dev/null 2>&1 || {
  echo "[FAIL] Kyverno CEL CRDs missing; run scripts/install-kyverno.sh"
  exit 1
}

"$CLI" get ns edl-data >/dev/null 2>&1 || {
  echo "[FAIL] edl-data namespace missing"
  exit 1
}

"$CLI" apply -f security/kyverno/no-latest.yaml
"$CLI" apply -f security/kyverno/require-resources-audit.yaml

echo "[PASS] I9 admission policies applied"
