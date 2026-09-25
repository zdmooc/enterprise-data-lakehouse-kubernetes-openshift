# Runbooks

Planned N3 scenarios:

- Node NotReady;
- API latency;
- DNS failure;
- ImagePullBackOff;
- Pending workload;
- OOMKilled;
- PVC/storage issue;
- GitOps OutOfSync/stuck sync;
- Kafka degradation;
- Spark job failure;
- Trino query failure;
- expired/invalid secret or certificate;
- blocked NetworkPolicy path.

Every runbook should follow:

```text
Signal
 -> impact
 -> fast triage
 -> evidence collection
 -> diagnosis
 -> remediation
 -> verification
 -> RCA / prevention
```
