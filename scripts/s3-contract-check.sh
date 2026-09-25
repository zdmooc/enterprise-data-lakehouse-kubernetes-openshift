#!/usr/bin/env bash
set -euo pipefail

required=(S3_ENDPOINT S3_BUCKET AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY)
for v in "${required[@]}"; do
  if [ -z "${!v:-}" ]; then
    echo "[FAIL] missing environment variable: $v"
    exit 1
  fi
done

command -v aws >/dev/null 2>&1 || {
  echo "[FAIL] aws CLI is required for the provider-neutral S3 contract test"
  exit 1
}

tmp="$(mktemp)"
out="$(mktemp)"
trap 'rm -f "$tmp" "$out"' EXIT

printf 'enterprise-data-lakehouse-s3-contract\n' > "$tmp"
key="contract-tests/$(date -u +%Y%m%dT%H%M%SZ)-$$.txt"

aws --endpoint-url "$S3_ENDPOINT" s3api head-bucket --bucket "$S3_BUCKET" >/dev/null

aws --endpoint-url "$S3_ENDPOINT" s3 cp "$tmp" "s3://$S3_BUCKET/$key" --only-show-errors
aws --endpoint-url "$S3_ENDPOINT" s3 cp "s3://$S3_BUCKET/$key" "$out" --only-show-errors

cmp "$tmp" "$out" || {
  echo "[FAIL] downloaded object differs from uploaded object"
  exit 1
}

aws --endpoint-url "$S3_ENDPOINT" s3 rm "s3://$S3_BUCKET/$key" --only-show-errors

echo "[PASS] S3 PUT/GET/integrity/DELETE contract validated"
