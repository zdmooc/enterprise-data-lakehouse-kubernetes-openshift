#!/usr/bin/env bash
set -euo pipefail
required=(S3_ENDPOINT S3_BUCKET AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY)
for v in "${required[@]}"; do
  [ -n "${!v:-}" ] || { echo "[FAIL] missing environment variable: $v"; exit 1; }
done
command -v aws >/dev/null 2>&1 || { echo "[FAIL] aws CLI required"; exit 1; }

bash scripts/s3-contract-check.sh

for prefix in raw curated checkpoints evidence; do
  aws --endpoint-url "$S3_ENDPOINT" s3api head-object     --bucket "$S3_BUCKET" --key "$prefix/.edl-zone" >/dev/null || {
      echo "[FAIL] missing S3 zone marker: $prefix"
      exit 1
    }
done

echo "[PASS] S3 contract and logical zone layout validated"
