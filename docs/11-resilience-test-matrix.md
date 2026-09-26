# I11 — Resilience and N3 Test Matrix

## Safety rule

CRC is single-node. It may prove pod/process recovery and diagnosis, but not node-level HA.

Destructive tests are restricted to `edl-data` and require explicit confirmation.

## Matrix

| Scenario | CRC | Multi-node target | Evidence expected |
|---|---|---|---|
| pod deletion/recreation | yes | yes | recovery time |
| OOMKilled | controlled | yes | signal + remediation |
| Pending pod | yes | yes | scheduler/event diagnosis |
| ImagePullBackOff | yes | yes | registry/image diagnosis |
| DNS failure/path | diagnostic only | yes | resolution path |
| NetworkPolicy block | yes | yes | denied/allowed proof |
| invalid/expired secret | synthetic | yes | failure + rotation |
| GitOps OutOfSync | yes | yes | detect/self-heal |
| Kafka pod failure | functional only | HA only on multi-node | continuity/recovery |
| worker NotReady | no HA claim | yes | reschedule/impact |
| storage failure | limited | yes | recovery/data integrity |
| Spark job failure | yes | yes | logs/retry/root cause |
| Trino query degradation | yes | yes | coordinator/worker/catalog diagnosis |

## N3 method

```text
signal
 -> business/data impact
 -> fast triage
 -> evidence snapshot
 -> hypothesis
 -> targeted test
 -> remediation
 -> functional verification
 -> RCA
 -> prevention
```

## Runtime boundary

I11 is only `RUNTIME_VALIDATED` after selected scenarios are executed and evidence is committed.

Multi-node HA remains pending until a suitable multi-node Kubernetes/OpenShift target exists.
