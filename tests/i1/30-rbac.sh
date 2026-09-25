#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

ensure_namespace
log "Testing namespace-scoped RBAC"

cat <<'YAML' | "$CLI" -n "$NS" apply -f - >/dev/null
apiVersion: v1
kind: ServiceAccount
metadata:
  name: data-engineer
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get","list","watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: data-engineer-pod-reader
subjects:
  - kind: ServiceAccount
    name: data-engineer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
YAML

SA="system:serviceaccount:$NS:data-engineer"

allow=$("$CLI" auth can-i list pods -n "$NS" --as="$SA" 2>/dev/null || true)
deny_secrets=$("$CLI" auth can-i list secrets -n "$NS" --as="$SA" 2>/dev/null || true)
deny_cluster=$("$CLI" auth can-i list nodes --as="$SA" 2>/dev/null || true)

[ "$allow" = "yes" ] || fail "service account cannot list pods in its namespace"
[ "$deny_secrets" = "no" ] || fail "service account unexpectedly can list secrets"
[ "$deny_cluster" = "no" ] || fail "service account unexpectedly can list cluster nodes"

pass "RBAC allows required pod read access and denies secrets/cluster-node access"
