#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
k create namespace kyverno --dry-run=client -o yaml | k apply -f -
k label namespace kyverno pod-security.kubernetes.io/enforce=restricted --overwrite
h upgrade --install kyverno kyverno --version 3.9.1 --namespace kyverno \
  --repo https://kyverno.github.io/kyverno/ --repository-config .audit/kind/repos.yaml \
  --repository-cache .audit/kind/helm-cache -f platform/kind/kyverno-values.yaml --wait --timeout=10m
guard
k apply -f security/kyverno/no-latest.yaml -f security/kyverno/require-resources-audit.yaml
k -n edl-data wait --for=condition=Ready namespacedvalidatingpolicy/disallow-latest-images --timeout=180s
export PATH="$ROOT/scripts/kind/portable-cli:$PATH"
bash scripts/test-security-negative-suite.sh | tee "$EVIDENCE_DIR/17-security-tests.txt"
k -n edl-data get namespacedvalidatingpolicy >> "$EVIDENCE_DIR/17-security-tests.txt"
resource_check | tee -a "$EVIDENCE_DIR/20-resource-usage.txt"
