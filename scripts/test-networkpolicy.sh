#!/usr/bin/env bash
set -euo pipefail
CLI=kubectl
command -v oc >/dev/null 2>&1 && CLI=oc

NS=data-platform-preflight
cleanup() { "$CLI" delete ns "$NS" --ignore-not-found >/dev/null 2>&1 || true; }
"$CLI" create ns "$NS" >/dev/null
trap cleanup EXIT

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
EOF

"$CLI" rollout status deploy/target -n "$NS" --timeout=120s >/dev/null
"$CLI" run network-client -n "$NS" --labels=access=allowed --image=curlimages/curl:8.10.1 --restart=Never --command -- sh -c 'sleep 600' >/dev/null
"$CLI" wait --for=condition=Ready pod/network-client -n "$NS" --timeout=120s >/dev/null
"$CLI" exec -n "$NS" network-client -- curl -fsS --max-time 10 http://target >/dev/null

cat <<'EOF' | "$CLI" apply -n "$NS" -f - >/dev/null
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
spec:
  podSelector: {}
  policyTypes: [Ingress]
EOF
sleep 3
# A successful exec transport plus curl timeout is required. DNS, HTTP, RBAC,
# image-pull and API errors must not be mistaken for NetworkPolicy enforcement.
denied="$("$CLI" exec -n "$NS" network-client -- sh -c 'curl -fsS --max-time 5 http://target >/dev/null 2>&1; printf "EDL_CURL_EXIT=%s\n" "$?"')"
[ "$denied" = "EDL_CURL_EXIT=28" ] || {
  echo "[FAIL] expected a network timeout; got: $denied"
  exit 1
}

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

sleep 3
"$CLI" exec -n "$NS" network-client -- curl -fsS --max-time 10 http://target >/dev/null
echo "[PASS] NetworkPolicy baseline, timeout and restored connectivity observed"
