#!/usr/bin/env bash
set -euo pipefail

required=(S3_ENDPOINT S3_BUCKET AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY)
for v in "${required[@]}"; do
  [ -n "${!v:-}" ] || { echo "[FAIL] missing environment variable: $v"; exit 1; }
done
command -v aws >/dev/null 2>&1 || { echo "[FAIL] aws CLI required"; exit 1; }

if ! aws --endpoint-url "$S3_ENDPOINT" s3api head-bucket --bucket "$S3_BUCKET" >/dev/null 2>&1; then
  if [ "${S3_CREATE_BUCKET:-no}" != "yes" ]; then
    echo "[FAIL] bucket $S3_BUCKET is unavailable; set S3_CREATE_BUCKET=yes only for an approved lab endpoint"
    exit 1
  fi
  aws --endpoint-url "$S3_ENDPOINT" s3api create-bucket --bucket "$S3_BUCKET" >/dev/null
fi

for prefix in raw curated checkpoints evidence; do
  printf 'edl-zone=%s\n' "$prefix" |     aws --endpoint-url "$S3_ENDPOINT" s3 cp - "s3://$S3_BUCKET/$prefix/.edl-zone" --only-show-errors
done

echo "[PASS] S3 Data Product zones are available in bucket $S3_BUCKET"
