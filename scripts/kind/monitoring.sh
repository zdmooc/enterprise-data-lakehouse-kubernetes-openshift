#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
if ! k -n edl-observability get secret kind-grafana-admin >/dev/null 2>&1; then
  umask 077
  { printf 'username=admin\npassword=%s\n' "$(openssl rand -hex 24)"; } > .audit/kind/grafana.env
  k -n edl-observability create secret generic kind-grafana-admin --from-env-file=.audit/kind/grafana.env
  rm -f .audit/kind/grafana.env
fi
h upgrade --install edl-monitoring kube-prometheus-stack --version 91.8.1 --namespace edl-observability \
  --repo https://prometheus-community.github.io/helm-charts --repository-config .audit/kind/repos.yaml \
  --repository-cache .audit/kind/helm-cache -f platform/kind/monitoring-values.yaml --wait --timeout=15m
guard
k apply -k observability/kind
k -n edl-observability create configmap edl-grafana-dashboards \
  --from-file=observability/grafana/edl-overview-dashboard.json \
  --from-file=observability/grafana/edl-data-pipeline-dashboard.json \
  --dry-run=client -o yaml | k apply -f -
k -n edl-observability label configmap edl-grafana-dashboards grafana_dashboard=1 --overwrite
py scripts/kind/test-monitoring.py | tee "$EVIDENCE_DIR/18-prometheus-targets.txt"
resource_check | tee -a "$EVIDENCE_DIR/20-resource-usage.txt"
