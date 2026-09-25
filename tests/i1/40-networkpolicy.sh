#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

ensure_namespace
log "Testing NetworkPolicy default deny and explicit allow"

cat <<'YAML' | "$CLI" -n "$NS" apply -f - >/dev/null
apiVersion: apps/v1
kind: Deployment
metadata:
  name: np-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: np-server
  template:
    metadata:
      labels:
        app: np-server
    spec:
      containers:
        - name: server
          image: busybox:1.36.1
          command: ["sh","-c","mkdir -p /www && echo ok >/www/index.html && httpd -f -p 8080 -h /www"]
          ports:
            - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: np-server
spec:
  selector:
    app: np-server
  ports:
    - port: 8080
      targetPort: 8080
---
apiVersion: v1
kind: Pod
metadata:
  name: np-client
  labels:
    app: np-client
spec:
  containers:
    - name: client
      image: busybox:1.36.1
      command: ["sh","-c","sleep 3600"]
YAML

"$CLI" -n "$NS" rollout status deployment/np-server --timeout=120s >/dev/null
"$CLI" -n "$NS" wait --for=condition=Ready pod/np-client --timeout=120s >/dev/null

"$CLI" -n "$NS" exec np-client -- wget -q -T 5 -O - http://np-server:8080 | grep -q '^ok$'   || fail "baseline connectivity failed before NetworkPolicy"

cat <<'YAML' | "$CLI" -n "$NS" apply -f - >/dev/null
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-np-server
spec:
  podSelector:
    matchLabels:
      app: np-server
  policyTypes:
    - Ingress
YAML

sleep 3
if "$CLI" -n "$NS" exec np-client -- wget -q -T 3 -O - http://np-server:8080 >/dev/null 2>&1; then
  fail "default-deny NetworkPolicy did not block client traffic"
fi

cat <<'YAML' | "$CLI" -n "$NS" apply -f - >/dev/null
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-np-client
spec:
  podSelector:
    matchLabels:
      app: np-server
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: np-client
      ports:
        - protocol: TCP
          port: 8080
YAML

sleep 3
"$CLI" -n "$NS" exec np-client -- wget -q -T 5 -O - http://np-server:8080 | grep -q '^ok$'   || fail "explicit allow NetworkPolicy did not restore connectivity"

pass "NetworkPolicy deny and explicit allow behavior validated"
