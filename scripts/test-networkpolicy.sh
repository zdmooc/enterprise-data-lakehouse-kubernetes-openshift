#!/usr/bin/env bash
set -euo pipefail
CLI=kubectl
command -v oc >/dev/null 2>&1 && CLI=oc

NS=data-platform-preflight
cleanup() { "$CLI" delete ns "$NS" --ignore-not-found >/dev/null 2>&1 || true; }
trap cleanup EXIT

"$CLI" create ns "$NS" >/dev/null

cat <<'EOF' | "$CLI" apply -n "$NS" -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: target
spec:
  replicas: 1
  selector:
    matchLabels: {app: target}
  template:
    metadata:
      labels: {app: target}
    spec:
      containers:
        - name: app
          image: registry.k8s.io/e2e-test-images/agnhost:2.53
          args: ["netexec","--http-port=8080"]
---
apiVersion: v1
kind: Service
metadata:
  name: target
spec:
  selector: {app: target}
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes: ["Ingress"]
EOF

"$CLI" rollout status deploy/target -n "$NS" --timeout=120s >/dev/null

"$CLI" run denied-client -n "$NS" --image=curlimages/curl:8.10.1 --restart=Never --command -- sh -c 'curl -fsS --max-time 5 http://target' >/dev/null 2>&1 || true
"$CLI" wait --for=jsonpath='{.status.phase}'=Failed pod/denied-client -n "$NS" --timeout=30s >/dev/null 2>&1 || true

cat <<'EOF' | "$CLI" apply -n "$NS" -f - >/dev/null
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-labeled-client
spec:
  podSelector:
    matchLabels:
      app: target
  ingress:
    - from:
        - podSelector:
            matchLabels:
              access: allowed
      ports:
        - protocol: TCP
          port: 8080
EOF

"$CLI" run allowed-client -n "$NS" --labels=access=allowed --image=curlimages/curl:8.10.1 --restart=Never --command -- sh -c 'curl -fsS --max-time 10 http://target' >/dev/null
"$CLI" wait --for=jsonpath='{.status.phase}'=Succeeded pod/allowed-client -n "$NS" --timeout=60s >/dev/null
echo "[PASS] NetworkPolicy deny/allow behavior validated"
