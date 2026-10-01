#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
exec > >(tee "$EVIDENCE_DIR/i2-contract.txt") 2>&1
inventory
guard
k apply -f platform/kind/contract-probe.yaml
k -n edl-data wait --for=condition=Ready pod/kind-contract --timeout=180s
k -n edl-data exec kind-contract -- nslookup kubernetes.default.svc.cluster.local
marker="kind-contract-$(date -u +%s)"
k -n edl-data exec kind-contract -- sh -c "printf '%s' '$marker' > /data/proof.txt"
k -n edl-data delete pod kind-contract --wait=true
k apply -f platform/kind/contract-probe.yaml
k -n edl-data wait --for=condition=Ready pod/kind-contract --timeout=180s
[ "$(k -n edl-data exec kind-contract -- cat /data/proof.txt)" = "$marker" ] || fail 'PVC persistence mismatch'
echo '[PASS] DNS in governed namespace and PVC write/read across pod recreation'
resource_check
