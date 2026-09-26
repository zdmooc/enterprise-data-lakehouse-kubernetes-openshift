#!/usr/bin/env bash
set -euo pipefail
CLI=kubectl
command -v oc >/dev/null 2>&1 && CLI=oc
"$CLI" get ns edl-data >/dev/null 2>&1 || { echo "[FAIL] edl-data namespace missing"; exit 1; }
"$CLI" apply -k data-platform/networking/base
echo "[PASS] Data Product explicit network flows applied"
