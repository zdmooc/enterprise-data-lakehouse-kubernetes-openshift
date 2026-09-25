# Runbook — Kafka Not Ready / Degraded

## Signal

- Kafka CR not Ready;
- broker/controller pod not Ready;
- producer/consumer timeout;
- consumer lag grows;
- under-replicated partitions.

## Fast triage

```bash
oc -n edl-data get kafka,kafkanodepool,pod,pvc
oc -n edl-data describe kafka edl-kafka
oc -n edl-data get events --sort-by=.lastTimestamp | tail -50
oc -n edl-data logs deployment/strimzi-cluster-operator --tail=200
```

Then inspect the affected Kafka pod logs.

## Decision tree

1. **Kafka CR not Ready but pods absent**
   - inspect Strimzi operator;
   - inspect CR status conditions;
   - inspect scheduling/PVC events.

2. **Pod Pending**
   - resources;
   - PVC binding;
   - node selector/taints;
   - quota.

3. **Pod restarting**
   - OOMKilled;
   - storage;
   - configuration;
   - certificate;
   - probe failures.

4. **Cluster Ready but clients fail**
   - bootstrap Service/DNS;
   - NetworkPolicy;
   - listener/TLS/auth;
   - client configuration.

5. **Lag grows**
   - consumer health;
   - partition availability;
   - processing throughput;
   - downstream dependency.

## Remediation rule

Do not delete PVCs or Kafka resources as a first response.

## Validation

```bash
bash scripts/test-kafka.sh
```

## CRC limitation

Single-broker CRC cannot demonstrate broker HA.
