#!/usr/bin/env bash
set -euo pipefail

command -v oc >/dev/null 2>&1 || { echo "[FAIL] oc is required"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "[FAIL] helm is required"; exit 1; }

required=(S3_ENDPOINT S3_BUCKET AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY)
for v in "${required[@]}"; do
  [ -n "${!v:-}" ] || { echo "[FAIL] missing environment variable: $v"; exit 1; }
done

NS=edl-data
POLARIS_VERSION="${POLARIS_VERSION:-1.7.0}"
S3_REGION="${S3_REGION:-us-east-1}"

oc get ns "$NS" >/dev/null 2>&1 || {
  echo "[FAIL] namespace $NS missing; apply I2 baseline first"
  exit 1
}

if command -v openssl >/dev/null 2>&1; then
  secret="$(openssl rand -hex 24)"
else
  secret="$(python - <<'PY'
import secrets
print(secrets.token_hex(24))
PY
)"
fi

oc -n "$NS" create secret generic polaris-bootstrap   --from-literal=credentials="POLARIS,root,$secret"   --dry-run=client -o yaml | oc apply -f -

oc -n "$NS" create secret generic polaris-client   --from-literal=CLIENT_ID=root   --from-literal=CLIENT_SECRET="$secret"   --from-literal=POLARIS_CREDENTIAL="root:$secret"   --dry-run=client -o yaml | oc apply -f -

oc -n "$NS" create secret generic polaris-s3   --from-literal=region="$S3_REGION"   --from-literal=accessKeyId="$AWS_ACCESS_KEY_ID"   --from-literal=secretAccessKey="$AWS_SECRET_ACCESS_KEY"   --dry-run=client -o yaml | oc apply -f -

helm repo add polaris https://downloads.apache.org/polaris/helm-chart --force-update >/dev/null
helm repo update >/dev/null

helm upgrade --install edl-polaris polaris/polaris   --version "$POLARIS_VERSION"   --namespace "$NS"   -f data-platform/catalog/polaris/values-crc.yaml   --wait   --timeout 10m

echo "[PASS] Polaris $POLARIS_VERSION installed"
echo "[INFO] client credentials are stored only in Kubernetes Secret polaris-client"
