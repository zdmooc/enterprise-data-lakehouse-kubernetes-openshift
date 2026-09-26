# I10 — SLI / SLO Proposal

These are lab reference objectives, not customer commitments.

## Platform SLIs

- pod readiness ratio in `edl-data`;
- unexpected restart rate;
- PVC bound state and free capacity;
- GitOps sync/health;
- API/DNS reachability from workloads.

## Data pipeline SLIs

- Kafka producer/consumer success;
- Kafka consumer lag;
- Spark job success/failure duration;
- Trino query success/failure;
- end-to-end Data Product freshness;
- Jupyter-to-Trino query success.

## Initial lab objectives

| Indicator | Lab objective |
|---|---|
| EDL critical workloads Ready | >= 99% during an active demo window |
| Kafka synthetic flow | 100% of test messages observed |
| Spark batch success | 100% for the controlled demo job |
| Trino smoke query | success on every acceptance run |
| E2E synthetic pipeline | completes without manual repair |
| GitOps baseline | Synced/Healthy outside controlled drift tests |

## Alert philosophy

Alerts must be actionable:
- symptom;
- impact;
- first diagnostic command;
- owning runbook.

Thresholds are tuned after runtime evidence. The repository does not claim production SLOs from CRC.
