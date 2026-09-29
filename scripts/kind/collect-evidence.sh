#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
guard
py scripts/kind/check-health.py | tee "$EVIDENCE_DIR/final-health.txt"
ready_nodes > "$EVIDENCE_DIR/04-nodes.txt"
k get namespaces > "$EVIDENCE_DIR/05-namespaces.txt"
k get pods -A -o wide > "$EVIDENCE_DIR/06-pods-all.txt"
k get services -A > "$EVIDENCE_DIR/07-services.txt"
k get pvc -A > "$EVIDENCE_DIR/08-pvc.txt"
k get storageclasses > "$EVIDENCE_DIR/09-storageclasses.txt"
k -n argocd get applications -o wide > "$EVIDENCE_DIR/argocd-final.txt"
h list -A > "$EVIDENCE_DIR/helm-releases.txt"
k -n edl-data get resourcequota,limitrange,networkpolicy > "$EVIDENCE_DIR/16-networkpolicies.txt"
{
  k -n edl-data get jobs
  k -n edl-data get pods -l spark-role
  grep 'Pi is roughly' "$EVIDENCE_DIR/spark-smoke.txt"
  grep -E 'EDL_EVENT_COUNT|EDL_ICEBERG_TABLE' "$EVIDENCE_DIR/spark-lakehouse.txt"
} > "$EVIDENCE_DIR/12-spark.txt"
resource_check > "$EVIDENCE_DIR/20-resource-usage-final.txt"
docker system df > "$EVIDENCE_DIR/21-docker-system-df.txt"
git rev-parse HEAD > "$EVIDENCE_DIR/runtime-revision.txt"
echo '[PASS] whitelist-only evidence captured; no Secrets, kubeconfig or full workload YAML exported'
