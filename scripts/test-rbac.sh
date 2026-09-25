#!/usr/bin/env bash
set -euo pipefail
CLI=kubectl
command -v oc >/dev/null 2>&1 && CLI=oc

NS=data-platform-preflight
cleanup() { "$CLI" delete ns "$NS" --ignore-not-found >/dev/null 2>&1 || true; }
trap cleanup EXIT

"$CLI" create ns "$NS" >/dev/null

cat <<'EOF' | "$CLI" apply -n "$NS" -f - >/dev/null
apiVersion: v1
kind: ServiceAccount
metadata:
  name: data-reader
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
  name: pod-reader
subjects:
  - kind: ServiceAccount
    name: data-reader
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
EOF

yes=$("$CLI" auth can-i list pods -n "$NS" --as="system:serviceaccount:$NS:data-reader")
no=$("$CLI" auth can-i delete pods -n "$NS" --as="system:serviceaccount:$NS:data-reader")

[ "$yes" = "yes" ] || { echo "[FAIL] expected list pods permission"; exit 1; }
[ "$no" = "no" ] || { echo "[FAIL] delete pods should be denied"; exit 1; }

echo "[PASS] RBAC allow/deny behavior validated"
