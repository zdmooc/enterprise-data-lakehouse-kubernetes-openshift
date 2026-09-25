#!/usr/bin/env bash
set -euo pipefail

if command -v oc >/dev/null 2>&1; then CLI=oc; else CLI=kubectl; fi

"$CLI" get crd kafkas.kafka.strimzi.io >/dev/null 2>&1 || {
  echo "[FAIL] Strimzi CRDs not found. Run scripts/install-strimzi.sh first."
  exit 1
}

"$CLI" apply -k data-platform/kafka/profiles/crc

echo "[INFO] waiting for Kafka edl-kafka"
"$CLI" -n edl-data wait kafka/edl-kafka --for=condition=Ready --timeout=600s

"$CLI" -n edl-data get kafka,kafkanodepool,kafkatopic
echo "[PASS] Kafka CRC profile reconciled"
