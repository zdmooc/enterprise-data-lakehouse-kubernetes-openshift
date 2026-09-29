#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
mapfile -t nodes < <(lab_nodes)
[ "${#nodes[@]}" = 3 ] || fail 'expected exactly the 3 edl-lab node containers'
docker stop --time 60 "${nodes[@]}"
echo '[PASS] edl-lab stopped; containers, images and volumes preserved'
