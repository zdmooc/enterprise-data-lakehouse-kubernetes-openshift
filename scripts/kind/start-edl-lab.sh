#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
crc_state="$(crc status 2>&1 || true)"
if printf '%s\n' "$crc_state" | grep -Eq 'CRC VM:.*Running'; then
  fail 'Stop CRC cleanly with crc stop first'
fi
mapfile -t nodes < <(lab_nodes)
[ "${#nodes[@]}" = 3 ] || fail 'expected existing 3 edl-lab containers; use create script for a new lab'
docker start "${nodes[@]}"
kind export kubeconfig --name "$CLUSTER"
kubectl config use-context "$CONTEXT"
ready_nodes
resource_check
