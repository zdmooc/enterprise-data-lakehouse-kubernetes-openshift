#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
[ "${CONFIRM_DELETE_EDL_LAB:-}" = yes ] || fail 'set CONFIRM_DELETE_EDL_LAB=yes; node-local data will be lost'
kind delete cluster --name "$CLUSTER"
echo '[INFO] only edl-lab deleted; no Docker prune and no CRC operation'
