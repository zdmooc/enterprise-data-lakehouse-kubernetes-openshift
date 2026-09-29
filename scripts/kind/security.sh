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
k -n edl-data wait --for=jsonpath='{.status.conditionStatus.ready}'=true namespacedvalidatingpolicy/disallow-latest-images --timeout=180s
k -n edl-data wait --for=jsonpath='{.status.conditionStatus.ready}'=true namespacedvalidatingpolicy/require-cpu-memory-resources --timeout=180s
export PATH="$ROOT/scripts/kind/portable-cli:$PATH"
bash scripts/test-security-negative-suite.sh | tee "$EVIDENCE_DIR/17-security-tests.txt"
k -n edl-data get pods -o json | py -c 'import json,sys; pods=json.load(sys.stdin)["items"]; missing=[p["metadata"]["name"]+"/"+c["name"] for p in pods for c in p["spec"]["containers"] if any(key not in c.get("resources",{}).get(kind,{}) for kind in ("requests","limits") for key in ("cpu","memory"))]; assert not missing, missing; print("[PASS] CPU and memory requests/limits present on every edl-data pod container; Kyverno resource policy is Audit")' | tee -a "$EVIDENCE_DIR/17-security-tests.txt"
k -n edl-data get namespacedvalidatingpolicy >> "$EVIDENCE_DIR/17-security-tests.txt"
resource_check | tee -a "$EVIDENCE_DIR/20-resource-usage.txt"
