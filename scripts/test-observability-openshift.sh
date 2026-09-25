#!/usr/bin/env bash
set -euo pipefail

command -v oc >/dev/null 2>&1 || { echo "[FAIL] oc required"; exit 1; }

for resource in   "podmonitor/edl-kafka-metrics"   "servicemonitor/edl-trino-coordinator"   "servicemonitor/edl-trino-worker"   "prometheusrule/edl-data-platform-rules"; do
  oc -n edl-data get "$resource" >/dev/null 2>&1 || {
    echo "[FAIL] missing monitoring resource: $resource"
    exit 1
  }
done

if oc -n edl-data get kafka edl-kafka >/dev/null 2>&1; then
  metricsType="$(oc -n edl-data get kafka edl-kafka -o jsonpath='{.spec.kafka.metricsConfig.type}' 2>/dev/null || true)"
  [ "$metricsType" = "strimziMetricsReporter" ] || {
    echo "[FAIL] Kafka metricsConfig is not strimziMetricsReporter"
    exit 1
  }
fi

if oc -n edl-data get service edl-trino >/dev/null 2>&1; then
  pod="$(oc -n edl-data get pod -l app.kubernetes.io/name=trino,app.kubernetes.io/component=coordinator -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
  if [ -n "$pod" ]; then
    out="$(oc -n edl-data exec "$pod" -- sh -c 'wget -qO- --header="X-Trino-User: prometheus" http://127.0.0.1:8080/metrics | head -n 5' 2>/dev/null || true)"
    [ -n "$out" ] || {
      echo "[FAIL] Trino /metrics endpoint did not return data"
      exit 1
    }
    printf '%s\n' "$out"
  fi
fi

echo "[PASS] observability resources and available workload metric endpoints validated"
