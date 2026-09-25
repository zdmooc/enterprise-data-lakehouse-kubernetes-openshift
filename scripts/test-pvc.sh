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
kind: PersistentVolumeClaim
metadata:
  name: preflight-pvc
spec:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 256Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: pvc-writer
spec:
  restartPolicy: Never
  containers:
    - name: writer
      image: busybox:1.36
      command: ["sh","-c","echo data-platform-ok > /data/probe && cat /data/probe"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: preflight-pvc
EOF

"$CLI" wait --for=jsonpath='{.status.phase}'=Succeeded pod/pvc-writer -n "$NS" --timeout=120s >/dev/null
writer=$("$CLI" logs -n "$NS" pvc-writer 2>/dev/null || true)
echo "$writer" | grep -q "data-platform-ok" || { echo "[FAIL] initial PVC write failed"; exit 1; }

"$CLI" delete pod pvc-writer -n "$NS" --wait=true >/dev/null

cat <<'EOF' | "$CLI" apply -n "$NS" -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: pvc-reader
spec:
  restartPolicy: Never
  containers:
    - name: reader
      image: busybox:1.36
      command: ["sh","-c","cat /data/probe"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: preflight-pvc
EOF

"$CLI" wait --for=jsonpath='{.status.phase}'=Succeeded pod/pvc-reader -n "$NS" --timeout=120s >/dev/null
reader=$("$CLI" logs -n "$NS" pvc-reader 2>/dev/null || true)
echo "$reader"
echo "$reader" | grep -q "data-platform-ok" || { echo "[FAIL] PVC persistence after pod recreation failed"; exit 1; }
echo "[PASS] PVC write/read persistence validated"
