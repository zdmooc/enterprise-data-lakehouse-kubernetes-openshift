# 04 — Lab Strategy

## Goal

Validate the architecture progressively without pretending that a laptop-sized environment represents a production Data platform.

## Profile A — Kubernetes The Hard Way / Vagrant

Use for:
- Kubernetes internals;
- control-plane understanding;
- PKI;
- etcd;
- CNI;
- kubelet;
- scheduling;
- troubleshooting;
- portability validation.

Reference:
`zdmooc/kubernetes-the-hard-way-vagrant-architect-v29`

Do not duplicate cluster bootstrap in this repository.

## Profile B — OpenShift Local / CRC

Use for:
- OpenShift APIs;
- Projects;
- Routes;
- SCC;
- Operators;
- OpenShift GitOps;
- Strimzi lab;
- lightweight Data component tests.

Important limitation:
CRC is single-node and resource-constrained. It does not prove:
- HA;
- node failure resilience;
- realistic Data throughput;
- production storage behavior.

## Profile C — Multi-node target

Required later for:
- Kafka replication/failure tests;
- scheduling across nodes;
- PodDisruptionBudget behavior;
- storage/failure scenarios;
- realistic Spark parallelism;
- upgrade/resilience exercises.

The target may later be OpenShift or Kubernetes on cloud/VM infrastructure depending on budget and mission preparation needs.

## Local resource strategy

Do not start all heavy services simultaneously.

Use staged profiles.

### Minimal profile

```text
Argo CD
MinIO
one lightweight producer
one validation consumer
```

### Streaming profile

```text
Kafka / Strimzi
MinIO
producer/consumer
Prometheus subset
```

### Processing profile

```text
MinIO
Spark job
small input dataset
```

### Query profile

```text
MinIO
Trino
Jupyter
```

### Full integration profile

Run only when resources allow:

```text
Kafka
Spark
MinIO
Trino
Jupyter
Prometheus/Grafana
GitOps
```

## Resource discipline

Every component must declare:
- requests;
- limits;
- persistence needs;
- ports;
- namespace/project;
- dependencies;
- minimum local footprint;
- cleanup procedure.

## Portability discipline

For each component, separate:

```text
base/
  portable Kubernetes resources

overlays/
  kubernetes/
  openshift/
```

Where OpenShift requires a specific Operator/API/security setting, document it explicitly instead of hiding the difference.

## Evidence

Each runtime validation must record:
- platform profile;
- cluster version;
- component version;
- commands executed;
- expected result;
- observed result;
- limitation.
