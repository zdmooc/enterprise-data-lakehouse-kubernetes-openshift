#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
ready_nodes
# Existing portable probes only receive a kubeconfig containing this Kind lab.
kind export kubeconfig --name "$CLUSTER" --kubeconfig .audit/kind/kubeconfig
export KUBECONFIG="$(cygpath -w "$ROOT/.audit/kind/kubeconfig")"
guard
bash tests/i1/run-all.sh 2>&1 | tee "$EVIDENCE_DIR/i1-contract.txt"
guard
bash tests/i1/cleanup.sh
resource_check | tee -a "$EVIDENCE_DIR/20-resource-usage.txt"
