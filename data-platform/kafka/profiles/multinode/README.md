# Kafka Multi-node Target

Reference target:
- 3 KRaft controllers;
- 3 brokers;
- replication factor 3;
- min ISR 2;
- persistent storage;
- TLS listener;
- metrics and Kafka Exporter.

This is an **architecture/implementation target**, not validated sizing.

Before runtime:
- ensure sufficient worker count and failure domains;
- add/validate pod anti-affinity or topology spread for the actual infrastructure;
- validate StorageClass semantics;
- validate resource sizing;
- validate disruption budgets and maintenance behavior.

CRC single-node must never run this profile as HA evidence.
