#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
# The runtime branch must already be pushed; neither main nor CRC is targeted.
k apply -k gitops/apps/kind-edl-lab
for app in kind-edl-baseline kind-edl-networking; do
  k -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced application/"$app" --timeout=300s
  k -n argocd wait --for=jsonpath='{.status.health.status}'=Healthy application/"$app" --timeout=300s
done
guard
k label namespace edl-data platform.maya.example/zone=kind-drift-test --overwrite
recovered=false
for attempt in $(seq 1 60); do
  zone="$(k get namespace edl-data -o jsonpath='{.metadata.labels.platform\.maya\.example/zone}')"
  if [ "$zone" = data ]; then recovered=true; break; fi
  sleep 5
done
[ "$recovered" = true ] || fail 'Argo baseline drift was not healed'
{
  k -n argocd get applications -o wide
  k -n argocd get pods
  echo '[PASS] baseline and networking synced/healthy; namespace label drift automatically healed'
} | tee "$EVIDENCE_DIR/10-argocd-applications.txt"
resource_check | tee -a "$EVIDENCE_DIR/20-resource-usage.txt"
