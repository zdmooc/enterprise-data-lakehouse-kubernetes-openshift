#!/usr/bin/env bash
set -euo pipefail

fail=0

info() { printf '[INFO] %s\n' "$*"; }
ok()   { printf '[ OK ] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
err()  { printf '[FAIL] %s\n' "$*"; fail=1; }

if command -v oc >/dev/null 2>&1; then
  CLI=oc
elif command -v kubectl >/dev/null 2>&1; then
  CLI=kubectl
else
  echo "[FAIL] neither oc nor kubectl was found"
  exit 1
fi

info "CLI: $CLI"

if ! "$CLI" version --client >/dev/null 2>&1; then
  err "CLI client is not functional"
else
  ok "CLI client available"
fi

if ! "$CLI" cluster-info >/dev/null 2>&1; then
  err "cluster API is not reachable with current context"
else
  ok "cluster API reachable"
fi

if "$CLI" api-resources 2>/dev/null | grep -q '^routes[[:space:]]'; then
  PLATFORM="openshift"
  ok "OpenShift Route API detected"
else
  PLATFORM="kubernetes"
  info "OpenShift Route API not detected; treating target as Kubernetes"
fi

info "Platform profile detected: $PLATFORM"

nodes=$("$CLI" get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
if [ "${nodes:-0}" -lt 1 ]; then
  err "no node visible"
else
  ok "$nodes node(s) visible"
fi

not_ready=$("$CLI" get nodes --no-headers 2>/dev/null | awk '$2 !~ /^Ready/ {print $1}' || true)
if [ -n "$not_ready" ]; then
  err "NotReady node(s): $not_ready"
else
  ok "all visible nodes are Ready"
fi

if "$CLI" get storageclass >/dev/null 2>&1; then
  sc_count=$("$CLI" get storageclass --no-headers 2>/dev/null | wc -l | tr -d ' ')
  if [ "${sc_count:-0}" -lt 1 ]; then
    warn "no StorageClass found; persistent Data services will need an explicit storage plan"
  else
    ok "$sc_count StorageClass(es) found"
  fi
else
  warn "StorageClass API check failed"
fi

if "$CLI" get ns kube-system >/dev/null 2>&1; then
  ok "kube-system namespace visible"
else
  err "kube-system namespace not visible"
fi

if [ "$PLATFORM" = "openshift" ]; then
  if "$CLI" get clusterversion >/dev/null 2>&1; then
    ok "OpenShift ClusterVersion resource visible"
  else
    warn "ClusterVersion not readable with current permissions"
  fi
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "[PASS] cluster satisfies the initial connectivity/readiness preflight."
  echo "Next checks: ingress/route, DNS workload test, dynamic PVC test, RBAC and NetworkPolicy."
else
  echo "[FAIL] one or more mandatory checks failed."
  exit 1
fi
