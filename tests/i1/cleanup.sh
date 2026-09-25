#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"
log "Deleting temporary namespace $NS"
delete_namespace
pass "cleanup complete"
