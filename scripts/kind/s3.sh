#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
if ! k -n edl-data get secret kind-s3 >/dev/null 2>&1; then
  umask 077
  secret_file=.audit/kind/s3.env
  {
    printf 'AWS_ACCESS_KEY_ID=edl%s\n' "$(openssl rand -hex 8)"
    printf 'AWS_SECRET_ACCESS_KEY=%s\n' "$(openssl rand -hex 24)"
    printf 'AWS_DEFAULT_REGION=us-east-1\nS3_BUCKET=edl-lab\nS3_ENDPOINT=http://edl-s3.edl-data.svc.cluster.local:9000\n'
  } > "$secret_file"
  k -n edl-data create secret generic kind-s3 --from-env-file="$secret_file"
  rm -f "$secret_file"
fi
k apply -k data-platform/object-storage/profiles/kind
k -n edl-data rollout status deployment/edl-s3 --timeout=600s
guard
k -n edl-data create configmap kind-s3-contract-scripts \
  --from-file=scripts/bootstrap-s3-layout.sh --from-file=scripts/verify-s3-layout.sh \
  --from-file=scripts/s3-contract-check.sh --dry-run=client -o yaml | k apply -f -
k -n edl-data delete job kind-s3-contract --ignore-not-found --wait=true
k apply -f platform/kind/s3-contract-job.yaml
if ! k -n edl-data wait --for=condition=Complete job/kind-s3-contract --timeout=600s; then
  k -n edl-data logs job/kind-s3-contract
  fail 'S3 contract failed'
fi
k -n edl-data logs job/kind-s3-contract | tee "$EVIDENCE_DIR/i4-s3-contract.txt"
resource_check | tee -a "$EVIDENCE_DIR/20-resource-usage.txt"
