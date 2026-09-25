#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

ensure_namespace
log "Checking workload exposure capability"

if "$CLI" api-resources 2>/dev/null | grep -q '^routes[[:space:]]'; then
  cat <<'YAML' | "$CLI" -n "$NS" apply -f - >/dev/null
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: np-server
spec:
  to:
    kind: Service
    name: np-server
  port:
    targetPort: 8080
YAML
  host=$("$CLI" -n "$NS" get route np-server -o jsonpath='{.spec.host}' 2>/dev/null || true)
  [ -n "$host" ] || fail "OpenShift Route was created but no host was assigned"
  pass "OpenShift Route API works; host assigned: $host"
  exit 0
fi

if "$CLI" api-resources 2>/dev/null | grep -q '^ingresses[[:space:]]'; then
  controllers=$("$CLI" get pods -A 2>/dev/null | grep -Ei 'ingress|traefik|nginx' | wc -l | tr -d ' ')
  if [ "${controllers:-0}" -gt 0 ]; then
    pass "Ingress API and at least one probable ingress controller detected"
  else
    warn "Ingress API exists but no ingress controller was confidently detected"
  fi
else
  warn "No OpenShift Route API or Kubernetes Ingress API detected"
fi
