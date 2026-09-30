#!/usr/bin/env bash
[[ "$(kubectl config current-context)" == kind-edl-lab ]] || exit 90
source "$(dirname "$0")/kind/common.sh"
guard
# I12 only; optional gate permits resuming without publishing a second event.
py scripts/kind/test-e2e.py "${1:-all}"
