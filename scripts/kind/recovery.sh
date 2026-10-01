#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
guard
# Optional scenario allows resuming without repeating completed replacements.
py scripts/kind/test-recovery.py "${1:-all}"
