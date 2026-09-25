#!/usr/bin/env bash
set -euo pipefail

if command -v oc >/dev/null 2>&1; then CLI=oc; else CLI=kubectl; fi

for ns in edl-platform edl-data edl-observability; do
  "$CLI" delete ns "$ns" --ignore-not-found=true --wait=false
done

echo "[INFO] baseline namespaces scheduled for deletion"
