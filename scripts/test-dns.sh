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
kind: Service
metadata:
  name: dns-target
spec:
  selector:
    app: dns-target
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dns-target
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dns-target
  template:
    metadata:
      labels:
        app: dns-target
    spec:
      containers:
        - name: app
          image: registry.k8s.io/e2e-test-images/agnhost:2.53
          args: ["netexec","--http-port=8080"]
EOF

"$CLI" rollout status deploy/dns-target -n "$NS" --timeout=120s >/dev/null
"$CLI" run dns-client -n "$NS" --image=busybox:1.36 --restart=Never --command -- sh -c 'nslookup dns-target && wget -qO- http://dns-target:80/hostname' >/dev/null
"$CLI" wait --for=jsonpath='{.status.phase}'=Succeeded pod/dns-client -n "$NS" --timeout=60s >/dev/null
logs=$("$CLI" logs -n "$NS" dns-client 2>&1 || true)
echo "$logs"
echo "$logs" | grep -q "dns-target" || { echo "[FAIL] DNS/service resolution failed"; exit 1; }
echo "[PASS] DNS and in-cluster service resolution validated"
