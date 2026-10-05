#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

echo "===== GIT ====="
git status --short --branch
echo "head=$(git rev-parse HEAD)"

echo "===== CONTEXT ====="
context="$(kubectl config current-context)"
echo "$context"
[ "$context" = "kind-edl-lab" ] || { echo "[FAIL] expected kind-edl-lab"; exit 1; }

echo "===== CRC ====="
crc_state="$(crc status 2>&1 || true)"
printf '%s
' "$crc_state"
if printf '%s
' "$crc_state" | grep -Eq 'CRC VM:.*Running|OpenShift:.*Running'; then
  echo "[FAIL] CRC is running"
  exit 1
fi

echo "===== DOCKER NODES ====="
for pair in   "edl-lab-control-plane:172.18.0.2"   "edl-lab-worker2:172.18.0.3"   "edl-lab-worker:172.18.0.4"; do
  node="${pair%%:*}"
  expected="${pair##*:}"
  running="$(docker inspect -f '{{.State.Running}}' "$node")"
  ip="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$node")"
  echo "$node running=$running ip=$ip"
  [ "$running" = "true" ] || exit 1
  [ "$ip" = "$expected" ] || exit 1
done

echo "===== NODES ====="
kubectl get nodes -o wide
kubectl wait --for=condition=Ready nodes --all --timeout=60s

echo "===== CALICO ====="
kubectl -n kube-system get pods -l k8s-app=calico-node -o wide
kubectl -n kube-system wait --for=condition=Ready pod -l k8s-app=calico-node --timeout=60s

echo "===== CORE DATA ====="
kubectl -n edl-data get pods
kubectl -n edl-data get pvc
kubectl -n edl-data get kafka edl-kafka

echo "===== ARGO ====="
kubectl -n argocd get applications

echo "===== OBSERVABILITY ====="
kubectl -n edl-observability get pods

echo "===== HEALTH GATE ====="
python scripts/kind/check-health.py

echo "[PASS] DEMO PREFLIGHT READY"
