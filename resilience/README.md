# I11 — Resilience / N3 Operations

## Goal

Turn the Data Platform from a collection of deployable components into an operable platform with repeatable diagnosis, controlled failure injection and evidence.

## Principles

- observe before changing;
- capture evidence before remediation;
- distinguish application failure from platform failure;
- use bounded, reversible tests;
- never run destructive tests on an unknown/shared environment;
- CRC single-node tests prove pod/process recovery only, never worker or zone resilience.

## Runtime scenarios

### CRC-capable

- delete Kafka pod and observe reconciliation;
- delete Trino worker and observe Deployment recovery;
- delete Jupyter pod and verify workspace persistence;
- force Spark job failure and inspect driver/executor events;
- create GitOps drift and observe self-heal;
- inspect PVC pressure and pod restarts.

### Multi-node only

- worker loss;
- Kafka broker/node loss with RF=3;
- PDB behavior;
- rescheduling across workers;
- storage node failure;
- control-plane degradation;
- rolling upgrade;
- capacity/failure-domain tests.

## Tools

- `scripts/collect-runtime-evidence.sh`
- `scripts/chaos-delete-pod.sh`
- runbooks under `runbooks/`
- evidence under `evidence/`

## Truth boundary

A successful pod replacement on CRC is not proof of:
- node HA;
- rack/zone HA;
- persistent-volume failover;
- production RTO/RPO;
- disaster recovery.
