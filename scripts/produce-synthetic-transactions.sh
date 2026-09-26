#!/usr/bin/env bash
set -euo pipefail
CLI=kubectl
command -v oc >/dev/null 2>&1 && CLI=oc
NS=edl-data
IMAGE="${KAFKA_CLIENT_IMAGE:-quay.io/strimzi/kafka@sha256:e90a1a74af4226f3ca4d1ebef3ab13bdb09754ae17ca4c1444f7fcbb0ca8ea9a}"
BOOTSTRAP="${KAFKA_BOOTSTRAP:-edl-kafka-kafka-bootstrap:9092}"
TOPIC="${KAFKA_TOPIC:-transactions.raw}"

"$CLI" -n "$NS" delete pod edl-transaction-producer --ignore-not-found=true --wait=true >/dev/null 2>&1 || true

payload='
{"eventId":"evt-0001","eventTime":"2026-09-26T18:00:00Z","transactionId":"txn-0001","amount":125.40,"currency":"EUR","status":"ACCEPTED","channel":"MOBILE","country":"FR","latencyMs":84}
{"eventId":"evt-0002","eventTime":"2026-09-26T18:00:01Z","transactionId":"txn-0002","amount":90.00,"currency":"EUR","status":"ACCEPTED","channel":"WEB","country":"FR","latencyMs":102}
{"eventId":"evt-0003","eventTime":"2026-09-26T18:00:02Z","transactionId":"txn-0003","amount":250.10,"currency":"EUR","status":"REJECTED","channel":"MOBILE","country":"DE","latencyMs":64}
{"eventId":"evt-0004","eventTime":"2026-09-26T18:00:03Z","transactionId":"txn-0004","amount":19.99,"currency":"EUR","status":"ACCEPTED","channel":"POS","country":"FR","latencyMs":45}
{"eventId":"evt-0005","eventTime":"2026-09-26T18:00:04Z","transactionId":"txn-0005","amount":800.00,"currency":"EUR","status":"PENDING","channel":"WEB","country":"BE","latencyMs":310}
'

encoded="$(printf '%s' "$payload" | base64 | tr -d '\n')"
"$CLI" -n "$NS" run edl-transaction-producer   --image="$IMAGE" --restart=Never --command -- bash -c   "printf '%s' '$encoded' | base64 -d | sed '/^[[:space:]]*$/d' | /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server '$BOOTSTRAP' --topic '$TOPIC'" >/dev/null

"$CLI" -n "$NS" wait pod/edl-transaction-producer --for=jsonpath='{.status.phase}'=Succeeded --timeout=180s >/dev/null || {
  "$CLI" -n "$NS" logs edl-transaction-producer || true
  exit 1
}

echo "[PASS] five synthetic JSON transaction events produced to $TOPIC"
