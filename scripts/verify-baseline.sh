#!/usr/bin/env bash
set -euo pipefail
CLI=kubectl
command -v oc >/dev/null 2>&1 && CLI=oc

for ns in edl-platform edl-data edl-observability; do
  "$CLI" get ns "$ns" >/dev/null
done

"$CLI" get resourcequota edl-data-quota -n edl-data >/dev/null
"$CLI" get limitrange default-container-limits -n edl-data >/dev/null
"$CLI" get sa data-workload -n edl-data >/dev/null
"$CLI" get role data-workload-reader -n edl-data >/dev/null
"$CLI" get rolebinding data-workload-reader -n edl-data >/dev/null
"$CLI" get networkpolicy default-deny-ingress -n edl-data >/dev/null
"$CLI" get networkpolicy default-deny-egress -n edl-data >/dev/null
"$CLI" get networkpolicy allow-dns-egress -n edl-data >/dev/null

yes=$("$CLI" auth can-i list pods -n edl-data --as=system:serviceaccount:edl-data:data-workload)
no=$("$CLI" auth can-i delete pods -n edl-data --as=system:serviceaccount:edl-data:data-workload)
[ "$yes" = "yes" ] || { echo "[FAIL] data-workload cannot list pods"; exit 1; }
[ "$no" = "no" ] || { echo "[FAIL] data-workload can delete pods"; exit 1; }

echo "[PASS] platform baseline validated"
