# I1 — Cluster Contract Runtime Tests

These tests validate the minimum Kubernetes/OpenShift contract required before installing Data Platform services.

## Test order

1. `00-preflight.sh` — API, nodes, storage classes and platform detection.
2. `10-dns.sh` — in-cluster DNS resolution.
3. `20-pvc.sh` — dynamic PVC write/read across pod recreation.
4. `30-rbac.sh` — namespace-scoped RBAC allow/deny.
5. `40-networkpolicy.sh` — default deny and explicit allow.
6. `50-exposure.sh` — OpenShift Route or Kubernetes Ingress capability discovery.

Run all:

```bash
bash tests/i1/run-all.sh
```

Cleanup:

```bash
bash tests/i1/cleanup.sh
```

## Evidence

The scripts print machine-readable PASS/FAIL lines. Capture the terminal output into an evidence file only after execution on a real target cluster.

## Safety

All runtime resources use the temporary namespace:

`edl-i1-contract-test`

No Data Platform component is installed during I1.
