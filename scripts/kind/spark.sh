#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
mode="${1:-smoke}"
[[ "$mode" = smoke || "$mode" = lakehouse ]] || fail 'expected smoke or lakehouse'
inventory
guard
for node in $(lab_nodes); do
  docker exec "$node" crictl inspecti docker.io/library/edl-spark-lakehouse:kind-4.1.3-iceberg1.11 >/dev/null || fail 'Run build-spark.sh to completion before submitting Spark'
done
k apply -k data-platform/spark/base
k -n edl-data create configmap kind-spark-templates \
  --from-file=pod.yaml=platform/kind/spark-template.yaml \
  --from-file=submit.sh=platform/kind/spark-submit.sh --dry-run=client -o yaml | k apply -f -
k -n edl-data delete job "kind-spark-$mode-submit" --ignore-not-found --wait=true
k -n edl-data delete pod "kind-spark-$mode-driver" --ignore-not-found --wait=true
sed "s/__MODE__/$mode/g" platform/kind/spark-job.yaml | k apply -f -
if ! wait_job "kind-spark-$mode-submit" 900; then
  k -n edl-data logs job/"kind-spark-$mode-submit"
  k -n edl-data logs "kind-spark-$mode-driver" || true
  fail "Spark $mode failed"
fi
k -n edl-data wait --for=jsonpath='{.status.phase}'=Succeeded pod/"kind-spark-$mode-driver" --timeout=60s
k -n edl-data logs "kind-spark-$mode-driver" > "$EVIDENCE_DIR/spark-$mode.txt"
if [ "$mode" = smoke ]; then
  grep 'Pi is roughly' "$EVIDENCE_DIR/spark-$mode.txt"
else
  grep -E 'EDL_EVENT_COUNT=[1-9][0-9]*' "$EVIDENCE_DIR/spark-$mode.txt"
fi
resource_check | tee -a "$EVIDENCE_DIR/20-resource-usage.txt"
