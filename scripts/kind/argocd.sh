#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
ready_nodes
k create namespace argocd --dry-run=client -o yaml | k apply -f -
k label namespace argocd pod-security.kubernetes.io/enforce=restricted pod-security.kubernetes.io/audit=restricted pod-security.kubernetes.io/warn=restricted --overwrite
guard
h upgrade --install argocd argo-cd --namespace argocd --version 10.9.2 \
  --repo https://argoproj.github.io/argo-helm \
  --repository-config .audit/kind/repos.yaml --repository-cache .audit/kind/helm-cache \
  -f platform/kind/argocd-values.yaml --wait --timeout 15m
k -n argocd get pods
k get crd applications.argoproj.io appprojects.argoproj.io
resource_check | tee -a "$EVIDENCE_DIR/20-resource-usage.txt"
