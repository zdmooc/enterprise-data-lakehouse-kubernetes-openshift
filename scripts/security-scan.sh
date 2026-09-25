#!/usr/bin/env bash
set -euo pipefail

TRIVY_VERSION="${TRIVY_VERSION:-0.74.0}"

if command -v trivy >/dev/null 2>&1; then
  exec trivy config --severity HIGH,CRITICAL --exit-code 1 .
fi

runtime=""
if command -v podman >/dev/null 2>&1; then
  runtime=podman
elif command -v docker >/dev/null 2>&1; then
  runtime=docker
else
  echo "[FAIL] install trivy or provide podman/docker"
  exit 1
fi

"$runtime" run --rm   -v "$PWD:/work:ro"   -w /work   "aquasec/trivy:$TRIVY_VERSION"   config --severity HIGH,CRITICAL --exit-code 1 .
