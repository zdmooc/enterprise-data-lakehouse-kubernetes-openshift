#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
scanner=.audit/kind/trivy/trivy.exe
[ -f "$scanner" ] || fail 'Install the checksum-verified Trivy 0.74.0 binary in .audit/kind/trivy first'
"$scanner" --version | tee "$EVIDENCE_DIR/trivy-version.txt"
"$scanner" fs --cache-dir .audit/kind/trivy-cache --scanners misconfig,secret \
  --skip-dirs .audit --skip-dirs .git --skip-dirs evidence \
  --format json --output .audit/kind/trivy-files.json .
for entry in 'spark:edl-spark-lakehouse:kind-4.1.3-iceberg1.11' 'jupyter:edl-jupyter:kind-2026-07-28' 's3:edl-s3-client:kind-2.31.0'; do
  name="${entry%%:*}"; image="${entry#*:}"
  "$scanner" image --cache-dir .audit/kind/trivy-cache --scanners vuln \
    --timeout 15m --format json --output ".audit/kind/trivy-$name.json" "$image"
done
py scripts/kind/summarize-trivy.py | tee "$EVIDENCE_DIR/i9-supply-chain.txt"
