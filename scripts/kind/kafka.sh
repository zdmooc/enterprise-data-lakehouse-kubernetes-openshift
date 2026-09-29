#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
h upgrade --install strimzi strimzi-kafka-operator --namespace edl-platform --version 1.2.0 \
  --repo https://strimzi.io/charts/ --repository-config .audit/kind/repos.yaml \
  --repository-cache .audit/kind/helm-cache -f platform/kind/strimzi-values.yaml --wait --timeout=10m
k -n edl-platform rollout status deployment/strimzi-cluster-operator --timeout=300s
guard
k apply -k data-platform/kafka/profiles/kind
k -n edl-data wait --for=condition=Ready kafka/edl-kafka --timeout=900s
k -n edl-data wait --for=condition=Ready kafkatopic/transactions.raw kafkatopic/edl.smoke --timeout=180s
{
  k get kafka,kafkanodepool,kafkatopic -n edl-data
  k get pods -n edl-data
} | tee "$EVIDENCE_DIR/11-kafka.txt"
resource_check | tee -a "$EVIDENCE_DIR/20-resource-usage.txt"
