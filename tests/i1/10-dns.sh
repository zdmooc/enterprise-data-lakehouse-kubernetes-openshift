#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

ensure_namespace
log "Testing in-cluster DNS in namespace $NS"

"$CLI" -n "$NS" delete pod dns-client --ignore-not-found=true --wait=true >/dev/null 2>&1 || true

"$CLI" -n "$NS" run dns-client   --image=busybox:1.36.1   --restart=Never   --command -- sh -c 'nslookup kubernetes.default.svc.cluster.local >/tmp/dns.out && cat /tmp/dns.out' >/dev/null

if "$CLI" -n "$NS" wait --for=jsonpath='{.status.phase}'=Succeeded pod/dns-client --timeout=120s >/dev/null 2>&1; then
  "$CLI" -n "$NS" logs dns-client
  pass "cluster DNS resolves kubernetes.default.svc.cluster.local"
else
  "$CLI" -n "$NS" describe pod dns-client || true
  "$CLI" -n "$NS" logs dns-client || true
  fail "cluster DNS test failed"
fi
