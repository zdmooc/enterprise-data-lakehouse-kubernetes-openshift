#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
export PATH="$ROOT/scripts/kind/portable-cli:$PATH"
export KAFKA_CLIENT_IMAGE=quay.io/strimzi/kafka:1.2.0-kafka-4.3.1
oc -n edl-data delete pod kind-kafka-client --ignore-not-found --wait=true
oc -n edl-data run kind-kafka-client --labels=edl.network/kafka-client=true \
  --image="$KAFKA_CLIENT_IMAGE" --restart=Never --command -- bash -c 'sleep 86400'
k -n edl-data wait --for=condition=Ready pod/kind-kafka-client --timeout=300s
marker="kind-kafka-$(date -u +%s)-$$"
k -n edl-data exec kind-kafka-client -- bash -ec "printf '%s\n' '$marker' | /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server edl-kafka-kafka-bootstrap:9092 --topic edl.smoke"
offset="$(k -n edl-data exec kind-kafka-client -- /opt/kafka/bin/kafka-get-offsets.sh --bootstrap-server edl-kafka-kafka-bootstrap:9092 --topic edl.smoke --time -1 | awk -F: '$2 == 0 {print $3}')"
[[ "$offset" =~ ^[0-9]+$ ]] && [ "$offset" -gt 0 ] || fail 'smoke partition has no records'
received="$(k -n edl-data exec kind-kafka-client -- /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server edl-kafka-kafka-bootstrap:9092 --topic edl.smoke --partition 0 --offset "$((offset-1))" --max-messages 1 --timeout-ms 30000)"
printf '%s\n' "$received" | grep -Fx "$marker" || fail 'fresh Kafka marker not consumed'
guard
# Reuse the repository producer unchanged; the adapter only supplies PSS fields.
bash scripts/produce-synthetic-transactions.sh
{
  echo "[PASS] fresh Kafka smoke marker produced and consumed: $marker at offset $((offset-1))"
  echo '[PASS] existing synthetic producer completed successfully'
  k -n edl-data get kafkatopic
} | tee -a "$EVIDENCE_DIR/11-kafka.txt"
resource_check | tee -a "$EVIDENCE_DIR/20-resource-usage.txt"
