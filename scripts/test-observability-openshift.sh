#!/usr/bin/env bash
set -euo pipefail

command -v oc >/dev/null 2>&1 || { echo "[FAIL] oc required"; exit 1; }

for resource in   "podmonitor/edl-kafka-metrics" "podmonitor/edl-kafka-exporter"   "servicemonitor/edl-trino-coordinator"   "servicemonitor/edl-trino-worker"   "prometheusrule/edl-data-platform-rules"; do
  oc -n edl-data get "$resource" >/dev/null 2>&1 || {
    echo "[FAIL] missing monitoring resource: $resource"
    exit 1
  }
done

oc -n edl-data get kafka edl-kafka >/dev/null
metricsType="$(oc -n edl-data get kafka edl-kafka -o jsonpath='{.spec.kafka.metricsConfig.type}')"
[ "$metricsType" = "strimziMetricsReporter" ] || {
  echo "[FAIL] Kafka metricsConfig is not strimziMetricsReporter"
  exit 1
}

oc -n edl-data get service edl-trino >/dev/null
pod="$(oc -n edl-data get pod -l app.kubernetes.io/name=trino,app.kubernetes.io/component=coordinator -o jsonpath='{.items[0].metadata.name}')"
[ -n "$pod" ] || { echo "[FAIL] Trino coordinator absent"; exit 1; }
out="$(oc -n edl-data exec "$pod" -- wget -qO- --header='X-Trino-User: prometheus' http://127.0.0.1:8080/metrics)"
[ -n "$out" ] || {
  echo "[FAIL] Trino /metrics endpoint did not return data"
  exit 1
}
printf '%s\n' "$out" | sed -n '1,5p'

echo "[PASS] monitoring objects and local Trino metrics found; Prometheus target UP, series and alert delivery still require evidence"
