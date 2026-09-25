#!/usr/bin/env bash
set -euo pipefail

if command -v oc >/dev/null 2>&1; then CLI=oc; else CLI=kubectl; fi

NS=edl-data
IMAGE="quay.io/strimzi/kafka@sha256:e90a1a74af4226f3ca4d1ebef3ab13bdb09754ae17ca4c1444f7fcbb0ca8ea9a"
BOOTSTRAP="edl-kafka-kafka-bootstrap:9092"
TOPIC="transactions.raw"
MESSAGE="edl-smoke-$(date -u +%Y%m%dT%H%M%SZ)-$$"

"$CLI" -n "$NS" delete pod kafka-smoke-producer kafka-smoke-consumer --ignore-not-found=true --wait=true >/dev/null 2>&1 || true

"$CLI" -n "$NS" run kafka-smoke-producer   --image="$IMAGE"   --restart=Never   --command -- bash -c "printf '%s\n' '$MESSAGE' | /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server '$BOOTSTRAP' --topic '$TOPIC'" >/dev/null

"$CLI" -n "$NS" wait pod/kafka-smoke-producer --for=jsonpath='{.status.phase}'=Succeeded --timeout=180s >/dev/null || {
  "$CLI" -n "$NS" logs kafka-smoke-producer || true
  exit 1
}

"$CLI" -n "$NS" run kafka-smoke-consumer   --image="$IMAGE"   --restart=Never   --command -- bash -c "/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server '$BOOTSTRAP' --topic '$TOPIC' --from-beginning --timeout-ms 30000" >/dev/null

"$CLI" -n "$NS" wait pod/kafka-smoke-consumer --for=jsonpath='{.status.phase}'=Succeeded --timeout=180s >/dev/null 2>&1 || true

logs=$("$CLI" -n "$NS" logs kafka-smoke-consumer 2>/dev/null || true)
printf '%s\n' "$logs"

printf '%s\n' "$logs" | grep -Fq "$MESSAGE" || {
  echo "[FAIL] produced message was not observed by consumer"
  exit 1
}

echo "[PASS] Kafka producer/consumer smoke test succeeded"
