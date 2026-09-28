#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL='*'
CLUSTER=edl-lab
CONTEXT=kind-edl-lab
mkdir -p .audit/kind
if [ ! -f .audit/kind/evidence-dir ]; then
  printf 'evidence/kind-edl-lab/%s\n' "$(date -u +%Y%m%dT%H%M%SZ)" > .audit/kind/evidence-dir
fi
EVIDENCE_DIR="$(cat .audit/kind/evidence-dir)"
mkdir -p "$EVIDENCE_DIR"
export EVIDENCE_DIR
fail() { echo "[FAIL] $*" >&2; exit 1; }
guard() {
  local current
  current="$(kubectl config current-context)"
  [ "$current" = "$CONTEXT" ] || fail "wrong context: $current; expected $CONTEXT"
}
k() { kubectl --context="$CONTEXT" "$@"; }
h() { helm --kube-context="$CONTEXT" "$@"; }
inventory() {
  kubectl config current-context || true
  crc status || true
  kind get clusters
  docker ps -a
  docker images
  docker volume ls
}
resource_check() {
  guard
  k get pods -A
  k top nodes || echo '[INFO] node metrics unavailable'
  k top pods -A || echo '[INFO] pod metrics unavailable'
  docker stats --no-stream
  docker system df
}
ready_nodes() {
  guard
  k wait --for=condition=Ready nodes --all --timeout=300s
  [ "$(k get nodes -o name | wc -l | tr -d ' ')" = 3 ] || fail 'expected exactly 3 Kind nodes'
  k get nodes -o wide
}
lab_nodes() {
  docker ps -aq --filter 'label=io.x-k8s.kind.cluster=edl-lab'
}
