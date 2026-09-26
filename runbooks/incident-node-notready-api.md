# Runbook — Node NotReady / API degradation

## Signal
- Node NotReady;
- API requests slow/failing;
- multiple unrelated workloads become unhealthy.

## Fast triage

```bash
oc get nodes -o wide
oc get --raw='/readyz?verbose'
oc get events -A --sort-by=.lastTimestamp
```

## Diagnose
- distinguish control-plane/API issue from one worker issue;
- inspect node conditions, pressure and recent events;
- correlate start time with platform changes.

## CRC boundary
A CRC single-node failure can stop all workloads. This is not evidence of HA behavior.

## Verification
- API ready;
- node Ready;
- EDL workloads Ready;
- Kafka/Trino/Jupyter smoke tests rerun where applicable.

Escalate to platform/infrastructure owner when the failure domain is below the workload layer.
