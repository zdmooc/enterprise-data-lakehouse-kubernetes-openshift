#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

[ "${CONFIRM_DEMO_SWITCH:-}" = "yes" ] || {
  echo "[STOP] Re-run with CONFIRM_DEMO_SWITCH=yes"
  exit 2
}

for cmd in docker kind kubectl crc; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "[FAIL] $cmd not found"; exit 1; }
done

CONTROL=edl-lab-control-plane
WORKER2=edl-lab-worker2
WORKER=edl-lab-worker

for node in "$CONTROL" "$WORKER2" "$WORKER"; do
  docker inspect "$node" >/dev/null 2>&1 || { echo "[FAIL] missing $node"; exit 1; }
done

echo "===== CRC ====="
crc_state="$(crc status 2>&1 || true)"
printf '%s
' "$crc_state"
if printf '%s
' "$crc_state" | grep -Eq 'CRC VM:.*Running|OpenShift:.*Running'; then
  crc stop
fi

stop_node() {
  local node="$1" state rc
  state="$(docker inspect -f '{{.State.Running}}' "$node")"
  [ "$state" = "true" ] || return 0
  set +e
  docker stop --timeout=30 "$node"
  rc=$?
  set -e
  sleep 3
  state="$(docker inspect -f '{{.State.Running}}' "$node")"
  if [ "$state" = "true" ]; then
    echo "[WARN] docker stop rc=$rc left $node running; using docker kill"
    docker kill "$node"
    sleep 2
  fi
  [ "$(docker inspect -f '{{.State.Running}}' "$node")" = "false" ] || { echo "[FAIL] cannot stop $node"; exit 1; }
}

echo "===== STOP KIND ====="
stop_node "$WORKER"
stop_node "$WORKER2"
stop_node "$CONTROL"

echo "===== START VALIDATED ORDER ====="
docker start "$CONTROL"; sleep 5
docker start "$WORKER2"; sleep 5
docker start "$WORKER"; sleep 8

expected_ip() {
  case "$1" in
    "$CONTROL") echo "172.18.0.2" ;;
    "$WORKER2") echo "172.18.0.3" ;;
    "$WORKER") echo "172.18.0.4" ;;
  esac
}

echo "===== DOCKER IP ====="
for node in "$CONTROL" "$WORKER2" "$WORKER"; do
  actual="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$node")"
  expected="$(expected_ip "$node")"
  echo "$node = $actual"
  [ "$actual" = "$expected" ] || { echo "[FAIL] expected $expected, got $actual"; exit 1; }
done

kind export kubeconfig --name edl-lab
kubectl config use-context kind-edl-lab >/dev/null

deadline=$((SECONDS + 300))
until kubectl --context=kind-edl-lab get nodes >/dev/null 2>&1; do
  [ "$SECONDS" -lt "$deadline" ] || { echo "[FAIL] Kind API timeout"; exit 1; }
  sleep 5
done

kubectl --context=kind-edl-lab wait --for=condition=Ready nodes --all --timeout=300s
kubectl --context=kind-edl-lab get nodes -o wide

kubectl --context=kind-edl-lab -n kube-system wait   --for=condition=Ready pod -l k8s-app=calico-node --timeout=300s

phase="$(kubectl --context=kind-edl-lab -n edl-data get pod kind-s3-reader -o jsonpath='{.status.phase}' 2>/dev/null || true)"
ready="$(kubectl --context=kind-edl-lab -n edl-data get pod kind-s3-reader -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || true)"
if [ "$phase" != "Running" ] || [ "$ready" != "true" ]; then
  kubectl --context=kind-edl-lab -n kyverno rollout status deployment/kyverno-admission-controller --timeout=300s
  kubectl --context=kind-edl-lab -n edl-data delete pod kind-s3-reader --ignore-not-found --wait=true
  kubectl --context=kind-edl-lab apply -f platform/kind/s3-reader.yaml
  kubectl --context=kind-edl-lab -n edl-data wait --for=condition=Ready pod/kind-s3-reader --timeout=300s
fi

python scripts/kind/check-health.py

echo "[PASS] CRC -> Kind switch complete"
echo "[NEXT] If Trino metadata is missing: CONFIRM_DEMO_RECOVERY=yes bash demo/scripts/03-restore-i12.sh"
