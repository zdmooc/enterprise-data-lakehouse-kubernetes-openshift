#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
# Build the existing audited Dockerfile with its original jobs context.
docker build -t edl-spark-lakehouse:kind-4.1.3-iceberg1.11 \
  -f data-platform/lakehouse/image/Dockerfile data-platform/lakehouse
kind load docker-image edl-spark-lakehouse:kind-4.1.3-iceberg1.11 --name "$CLUSTER"
docker image inspect edl-spark-lakehouse:kind-4.1.3-iceberg1.11 --format '{{.Id}}' | tee "$EVIDENCE_DIR/spark-image.txt"
