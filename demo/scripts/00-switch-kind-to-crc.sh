#!/usr/bin/env bash
set -Eeuo pipefail

# D-098 / demo helper:
# leave the retained Kind Data Lakehouse stopped and CRC/OpenShift active.
# No Kind delete, no namespace/PVC deletion, no Data Lakehouse replay.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

[ "${CONFIRM_DEMO_SWITCH:-}" = "yes" ] || {
  echo "[STOP] Re-run with CONFIRM_DEMO_SWITCH=yes"
  exit 2
}

for cmd in docker kind kubectl crc oc; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "[FAIL] $cmd not found"; exit 1; }
done

CONTROL=edl-lab-control-plane
WORKER2=edl-lab-worker2
WORKER=edl-lab-worker
NODES=("$CONTROL" "$WORKER2" "$WORKER")
CRC_STARTED=false
KIND_STOPPED=false
SUCCESS=false

restore_kind_on_failure() {
  local rc=$?
  if [ "$SUCCESS" = true ]; then
    return 0
  fi
  echo "[WARN] switch failed; attempting to restore Kind" >&2
  if [ "$CRC_STARTED" = true ]; then
    crc stop >/dev/null 2>&1 || true
  fi
  if [ "$KIND_STOPPED" = true ]; then
    docker start "$CONTROL" >/dev/null 2>&1 || true
    sleep 4
    docker start "$WORKER2" >/dev/null 2>&1 || true
    sleep 3
    docker start "$WORKER" >/dev/null 2>&1 || true
    sleep 5
    kind export kubeconfig --name edl-lab >/dev/null 2>&1 || true
    kubectl config use-context kind-edl-lab >/dev/null 2>&1 || true
  fi
  return "$rc"
}
trap restore_kind_on_failure EXIT

echo "===== VERIFY RETAINED KIND ====="
for node in "${NODES[@]}"; do
  docker inspect "$node" >/dev/null 2>&1 || { echo "[FAIL] missing $node"; exit 1; }
done

kind export kubeconfig --name edl-lab >/dev/null
kubectl config use-context kind-edl-lab >/dev/null
kubectl --context=kind-edl-lab wait --for=condition=Ready nodes --all --timeout=300s
kubectl --context=kind-edl-lab get nodes -o wide

echo "===== STOP LOCAL DEMO PORT-FORWARDS ====="
bash demo/scripts/06-stop-interfaces.sh >/dev/null 2>&1 || true

echo "===== VERIFY CRC IS NOT ALREADY RUNNING ====="
crc_state="$(crc status 2>&1 || true)"
printf '%s\n' "$crc_state"
if printf '%s\n' "$crc_state" | grep -Eq 'CRC VM:.*Running|OpenShift:.*Running'; then
  echo "[FAIL] CRC already appears to be running while Kind is active"
  exit 1
fi

stop_node() {
  local node="$1" state rc
  state="$(docker inspect -f '{{.State.Running}}' "$node" 2>/dev/null || true)"
  [ "$state" = "true" ] || return 0
  set +e
  docker stop --timeout=30 "$node"
  rc=$?
  set -e
  sleep 3
  state="$(docker inspect -f '{{.State.Running}}' "$node" 2>/dev/null || true)"
  if [ "$state" = "true" ]; then
    echo "[WARN] docker stop rc=$rc left $node running; using docker kill"
    docker kill "$node"
    sleep 2
  fi
  [ "$(docker inspect -f '{{.State.Running}}' "$node" 2>/dev/null || true)" != "true" ]     || { echo "[FAIL] cannot stop $node"; exit 1; }
}

echo "===== STOP KIND WITHOUT DELETION ====="
KIND_STOPPED=true
stop_node "$WORKER"
stop_node "$WORKER2"
stop_node "$CONTROL"

for node in "${NODES[@]}"; do
  [ "$(docker inspect -f '{{.State.Running}}' "$node")" = "false" ]     || { echo "[FAIL] $node still running"; exit 1; }
done

echo "===== START CRC ====="
CRC_STARTED=true
crc start

kubectl config use-context crc-admin >/dev/null
kubectl --context=crc-admin wait --for=condition=Ready nodes --all --timeout=600s

echo "===== CRC / OPENSHIFT ====="
crc status
oc whoami
oc whoami --show-server
oc get clusterversion
oc get clusteroperators
oc get nodes -o wide

SUCCESS=true
trap - EXIT

echo "[PASS] Kind retained/stopped; CRC/OpenShift active"
echo "[NEXT] Run D-098 SQY runtime evidence from the owning repositories."
echo "[RETURN] CONFIRM_DEMO_SWITCH=yes bash demo/scripts/01-switch-crc-to-kind.sh"
