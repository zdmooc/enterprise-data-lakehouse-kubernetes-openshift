#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

ensure_namespace
log "Testing dynamic PVC provisioning and persistence"

if [ -z "$("$CLI" get storageclass --no-headers 2>/dev/null | head -n1)" ]; then
  fail "no StorageClass available"
fi

cat <<'YAML' | "$CLI" -n "$NS" apply -f - >/dev/null
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: contract-pvc
spec:
  accessModes:
    - ReadWriteOnce
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
      image: busybox:1.36.1
      command: ["sh","-c","echo enterprise-data-lakehouse > /data/proof.txt && sync && cat /data/proof.txt"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: contract-pvc
YAML

"$CLI" -n "$NS" wait --for=jsonpath='{.status.phase}'=Succeeded pod/pvc-writer --timeout=180s >/dev/null || {
  "$CLI" -n "$NS" describe pod pvc-writer || true
  "$CLI" -n "$NS" get pvc contract-pvc -o wide || true
  fail "PVC writer did not complete"
}

"$CLI" -n "$NS" delete pod pvc-writer --wait=true >/dev/null

cat <<'YAML' | "$CLI" -n "$NS" apply -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: pvc-reader
spec:
  restartPolicy: Never
  containers:
    - name: reader
      image: busybox:1.36.1
      command: ["sh","-c","test \"$(cat /data/proof.txt)\" = enterprise-data-lakehouse && cat /data/proof.txt"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: contract-pvc
YAML

if "$CLI" -n "$NS" wait --for=jsonpath='{.status.phase}'=Succeeded pod/pvc-reader --timeout=180s >/dev/null 2>&1; then
  "$CLI" -n "$NS" logs pvc-reader
  pass "PVC data survived pod recreation"
else
  "$CLI" -n "$NS" describe pod pvc-reader || true
  "$CLI" -n "$NS" logs pvc-reader || true
  fail "PVC persistence test failed"
fi
