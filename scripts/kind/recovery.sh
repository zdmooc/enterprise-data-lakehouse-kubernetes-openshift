#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
exec > >(tee "$EVIDENCE_DIR/i11-recovery.txt") 2>&1
export PATH="$ROOT/scripts/kind/portable-cli:$PATH"
bash scripts/n3-diagnostics.sh > "$EVIDENCE_DIR/i11-diagnostics.txt"
export CONFIRM_CHAOS=yes NAMESPACE=edl-data
SELECTOR='app.kubernetes.io/component=worker,app.kubernetes.io/name=trino' bash scripts/chaos-delete-pod.sh
guard
SELECTOR='app=edl-jupyter' bash scripts/chaos-delete-pod.sh
k -n edl-data exec deployment/edl-jupyter -- python -c 'from pathlib import Path; assert Path("/home/jovyan/work/kind-volume-proof.txt").read_text()=="kind-jupyter-persistence"; print("[PASS] Jupyter PVC survived replacement")'
k -n edl-data exec deployment/edl-jupyter -- python /opt/edl-samples/trino_lakehouse_query.py
guard
old="$(k -n edl-data get pod edl-kafka-dual-role-0 -o jsonpath='{.metadata.uid}')"
k -n edl-data delete pod edl-kafka-dual-role-0 --wait=true
recovered=false
for attempt in $(seq 1 120); do
  state="$(k -n edl-data get pod edl-kafka-dual-role-0 -o jsonpath='{.metadata.uid}:{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
  if [[ "$state" = *:True ]] && [[ "$state" != "$old":* ]]; then recovered=true; break; fi
  sleep 5
done
[ "$recovered" = true ] || fail 'Kafka replacement with new UID did not become Ready'
k -n edl-data exec kind-kafka-client -- /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server edl-kafka-kafka-bootstrap:9092 --topic edl.smoke \
  --partition 0 --offset earliest --max-messages 1 --timeout-ms 30000
echo '[PASS] KIND_MULTI_NODE_FUNCTIONAL_RECOVERY: Trino worker, Jupyter PVC/query, Kafka replacement and retained record'
resource_check | tee -a "$EVIDENCE_DIR/20-resource-usage.txt"
