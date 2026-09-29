#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
for namespace in argocd edl-platform edl-data edl-observability kyverno; do
  if k get namespace "$namespace" >/dev/null 2>&1; then
    for deployment in $(k -n "$namespace" get deployments -o name); do
      k -n "$namespace" rollout status "$deployment" --timeout=600s
    done
  fi
done
k -n edl-data wait --for=condition=Ready kafka/edl-kafka --timeout=600s
# The in-memory lab catalog loses metadata on process restart. Recreate its
# contract, then replay retained Kafka records through the existing batch job.
py scripts/kind/polaris.py bootstrap
bash scripts/kind/spark.sh lakehouse
if k -n edl-data get deployment edl-jupyter >/dev/null 2>&1; then
  k -n edl-data exec deployment/edl-jupyter -- python /opt/edl-samples/trino_lakehouse_query.py
fi
echo '[PASS] lab catalog and table rebuilt from retained Kafka records'
