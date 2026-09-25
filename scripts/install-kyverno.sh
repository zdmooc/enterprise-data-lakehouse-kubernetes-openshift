#!/usr/bin/env bash
set -euo pipefail

if command -v oc >/dev/null 2>&1; then CLI=oc; else CLI=kubectl; fi

VERSION="${KYVERNO_VERSION:-v1.19.1}"
URL="https://github.com/kyverno/kyverno/releases/download/${VERSION}/install.yaml"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

echo "[INFO] downloading Kyverno $VERSION"
curl -L --fail --retry 3 -o "$tmp" "$URL"
"$CLI" apply -f "$tmp"

echo "[INFO] waiting for Kyverno admission controller"
"$CLI" -n kyverno rollout status deployment/kyverno-admission-controller --timeout=300s

"$CLI" get crd validatingpolicies.policies.kyverno.io >/dev/null
echo "[PASS] Kyverno $VERSION available with CEL policy CRDs"
