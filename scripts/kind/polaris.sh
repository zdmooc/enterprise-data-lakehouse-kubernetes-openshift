#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
py scripts/kind/polaris.py secrets
h upgrade --install edl-polaris polaris --version 1.7.0 --namespace edl-data \
  --repo https://downloads.apache.org/polaris/helm-chart \
  --repository-config .audit/kind/repos.yaml --repository-cache .audit/kind/helm-cache \
  -f data-platform/catalog/polaris/values-kind.yaml --wait --timeout=10m
guard
py scripts/kind/polaris.py bootstrap | tee "$EVIDENCE_DIR/13-polaris.txt"
resource_check | tee -a "$EVIDENCE_DIR/20-resource-usage.txt"
