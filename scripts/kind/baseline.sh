#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
ready_nodes
k apply -k platform/baseline/overlays/kind
k apply -k data-platform/networking/base
k get ns > "$EVIDENCE_DIR/05-namespaces.txt"
k get resourcequota,limitrange,serviceaccount,role,rolebinding,networkpolicy -n edl-data > "$EVIDENCE_DIR/16-networkpolicies.txt"
sa=system:serviceaccount:edl-data:data-workload
[ "$(k auth can-i list pods -n edl-data --as="$sa")" = yes ] || fail 'pod read RBAC'
[ "$(k auth can-i get secrets -n edl-data --as="$sa" || true)" = no ] || fail 'secret read unexpectedly allowed'
[ "$(k auth can-i delete pods -n edl-data --as="$sa" || true)" = no ] || fail 'pod deletion unexpectedly allowed'
echo '[PASS] data-workload: pod reads allowed; secret reads and pod deletion denied' | tee "$EVIDENCE_DIR/i2-rbac.txt"
resource_check | tee -a "$EVIDENCE_DIR/20-resource-usage.txt"
