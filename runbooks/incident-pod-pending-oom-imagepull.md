# Runbook — Pending / OOMKilled / ImagePullBackOff

## Triage

```bash
oc -n edl-data get pods -o wide
oc -n edl-data describe pod <pod>
oc -n edl-data get events --sort-by=.lastTimestamp
```

## Pending
Check:
- ResourceQuota;
- LimitRange;
- node capacity;
- PVC binding;
- affinity/taints;
- image pull preconditions.

## OOMKilled
Check:
- previous container logs;
- memory request/limit;
- Spark/Trino JVM or executor sizing;
- recent workload growth.

Do not simply increase memory without identifying the workload cause.

## ImagePullBackOff
Check:
- exact image reference;
- registry reachability;
- ImageStream state on OpenShift;
- pull secret only through metadata/status, never export secret values.

## Verify
Workload Ready and its component smoke test passes.
