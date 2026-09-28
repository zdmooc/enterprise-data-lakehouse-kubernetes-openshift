#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
crc_state="$(crc status 2>&1 || true)"
if printf '%s\n' "$crc_state" | grep -Eq 'CRC VM:.*Running'; then
  fail 'CRC is running. Stop it cleanly with crc stop before creating Kind.'
fi
if ! kind get clusters | grep -qx "$CLUSTER"; then
  kind create cluster --config platform/kind/kind-edl-lab.yaml
fi
kubectl config use-context "$CONTEXT"
guard
# kindnet does not enforce NetworkPolicy; install an enforcing CNI before I1.
curl --fail --location --retry 3 https://raw.githubusercontent.com/projectcalico/calico/v3.30.3/manifests/calico.yaml -o .audit/kind/calico.yaml
k apply --server-side -f .audit/kind/calico.yaml
k -n kube-system rollout status daemonset/calico-node --timeout=600s
ready_nodes | tee "$EVIDENCE_DIR/04-nodes.txt"
kind version > "$EVIDENCE_DIR/01-kind-version.txt"
docker version > "$EVIDENCE_DIR/02-docker-version.txt"
kubectl version --client > "$EVIDENCE_DIR/03-kubectl-version.txt"
resource_check | tee "$EVIDENCE_DIR/20-resource-usage.txt"
