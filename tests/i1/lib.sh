#!/usr/bin/env bash
set -euo pipefail

NS="${NS:-edl-i1-contract-test}"

if command -v oc >/dev/null 2>&1; then
  CLI=oc
elif command -v kubectl >/dev/null 2>&1; then
  CLI=kubectl
else
  echo "[FAIL] neither oc nor kubectl found"
  exit 1
fi

log()  { printf '[INFO] %s\n' "$*"; }
pass() { printf '[PASS] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
fail() { printf '[FAIL] %s\n' "$*" >&2; exit 1; }

ensure_namespace() {
  "$CLI" get ns "$NS" >/dev/null 2>&1 || "$CLI" create ns "$NS" >/dev/null
}

wait_pod_ready() {
  local selector="$1"
  "$CLI" -n "$NS" wait --for=condition=Ready pod -l "$selector" --timeout=120s >/dev/null
}

delete_namespace() {
  "$CLI" delete ns "$NS" --ignore-not-found=true --wait=true >/dev/null 2>&1 || true
}
