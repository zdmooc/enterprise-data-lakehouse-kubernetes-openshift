#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
h upgrade --install edl-trino trino --version 1.42.2 --namespace edl-data \
  --repo https://trinodb.github.io/charts/ \
  --repository-config .audit/kind/repos.yaml --repository-cache .audit/kind/helm-cache \
  -f data-platform/trino/values-kind.yaml -f data-platform/trino/values-lakehouse.yaml \
  --wait --timeout=10m
coordinator="$(k -n edl-data get pod -l app.kubernetes.io/component=coordinator -o jsonpath='{.items[0].metadata.name}')"
{
  k -n edl-data exec "$coordinator" -- trino --server http://localhost:8080 --user edl --execute 'SELECT 1'
  k -n edl-data exec "$coordinator" -- trino --server http://localhost:8080 --user edl --execute 'SELECT count(*) FROM tpch.tiny.nation'
  k -n edl-data exec "$coordinator" -- trino --server http://localhost:8080 --user edl --execute 'SELECT eventId, transactionId, amount, status FROM polaris.analytics.transactions ORDER BY eventId'
} | tee "$EVIDENCE_DIR/14-trino.txt"
resource_check | tee -a "$EVIDENCE_DIR/20-resource-usage.txt"
