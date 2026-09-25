#!/usr/bin/env bash
set -euo pipefail

if command -v oc >/dev/null 2>&1; then CLI=oc; else CLI=kubectl; fi

NS="${STRIMZI_NAMESPACE:-edl-data}"
VERSION="${STRIMZI_VERSION:-1.2.0}"
URL="https://github.com/strimzi/strimzi-kafka-operator/releases/download/${VERSION}/strimzi-cluster-operator-${VERSION}.yaml"

"$CLI" get ns "$NS" >/dev/null 2>&1 || "$CLI" create ns "$NS"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

echo "[INFO] downloading Strimzi $VERSION"
curl -L --fail --retry 3 -o "$tmp" "$URL"

# Strimzi release installation YAML uses the default example namespace.
sed "s/namespace: myproject/namespace: $NS/g" "$tmp" | "$CLI" create -f - -n "$NS" || {
  echo "[INFO] resources may already exist; applying update"
  sed "s/namespace: myproject/namespace: $NS/g" "$tmp" | "$CLI" apply -f - -n "$NS"
}

echo "[INFO] waiting for Strimzi Cluster Operator"
"$CLI" -n "$NS" rollout status deployment/strimzi-cluster-operator --timeout=300s

"$CLI" get crd kafkas.kafka.strimzi.io >/dev/null
api=$("$CLI" get crd kafkas.kafka.strimzi.io -o jsonpath='{.spec.versions[?(@.served==true)].name}' 2>/dev/null || true)
echo "[INFO] served Kafka CRD versions: $api"

echo "[PASS] Strimzi operator available"
