#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
# Trino's local unauthenticated-user mode needs an identity and an empty password.
# This Operator requires both Secret selectors even when the password is empty.
k -n edl-data create secret generic kind-trino-metrics \
  --from-literal=username=prometheus --from-literal=password= \
  --dry-run=client -o yaml | k apply -f -
k apply -f observability/kind/trino-servicemonitors.yaml
