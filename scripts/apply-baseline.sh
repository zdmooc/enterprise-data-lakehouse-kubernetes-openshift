#!/usr/bin/env bash
set -euo pipefail
PROFILE="${1:-openshift}"
CLI=kubectl
command -v oc >/dev/null 2>&1 && CLI=oc
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
case "$PROFILE" in
  openshift|kubernetes) ;;
  *) echo "usage: $0 [openshift|kubernetes]"; exit 2 ;;
esac
"$CLI" apply -k "$ROOT/platform/baseline/overlays/$PROFILE"
echo "[PASS] baseline applied for profile: $PROFILE"
