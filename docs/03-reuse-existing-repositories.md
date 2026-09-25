# 03 — Reuse Existing Repositories

## Principle

This repository is an **integration and architecture repository** for enterprise Data workloads on Kubernetes/OpenShift.

It must reuse proven knowledge from specialist repositories rather than clone their full content.

## Reuse matrix

| Existing repository | Reused capability | What stays in the specialist repo |
|---|---|---|
| `kubernetes-the-hard-way-vagrant-architect-v29` | local K8s from scratch, HA topology, PKI, OIDC, GitOps, observability | low-level cluster build |
| `kubernetes-the-hard-way-multicloud` | provider-independent K8s internals and architecture | multi-cloud provisioning |
| `k8s-openshift-cluster-factory` | CaaS, Day-2, upgrade, N2/N3 runbooks | generic cluster factory |
| `openshift-platform-blueprints` | OpenShift architecture patterns | broad OpenShift portfolio |
| `argocd-complete-masterclass` | Argo CD patterns, Helm, Kustomize | Argo CD learning/reference |
| `argocd-expert-pack` | OpenShift GitOps and operational runbooks | Argo CD deep-dive |
| `kafka-data-engineer-kafkaops-topic-service-crc` | Strimzi/Kafka, KafkaOps, support patterns | Kafka specialist implementation |
| `mayabank-kafka-ddd-openshift` | event-driven architecture and product framing | domain-driven Kafka architecture |
| `elk-log-data-platform` | OpenSearch/ELK/logging and pipeline ideas | log-centric Data platform |
| `maya-secure-agentic-devsecops-platform` | Trivy, Grype, Cosign, policy and supply-chain patterns | DevSecOps specialist implementation |
| `dynatrace-observability-senior-project` | RCA/N3/SRE operating model ideas | Dynatrace-specific implementation |
| `mayabank-ibm-mq-native-ha-openshift-eda-platform` | evidence discipline, resilience and OpenShift runtime practices | IBM MQ domain |

## Rules

### Reuse by reference

Preferred:
- link to source repository;
- copy only a small pattern that is adapted to this Data Platform;
- document origin and adaptation.

### Do not fork blindly

Do not copy:
- entire directories;
- obsolete manifests;
- version-pinned resources without compatibility checks;
- evidence from another lab as evidence for this repository.

### Evidence isolation

A deployment proved in another repository may be cited as prior work, but it is **not runtime evidence** for this project.

## Target integration model

```text
KTHW repositories
      |
      +------> Cluster target
                    |
k8s-openshift-cluster-factory
      |
      +------> Platform baseline
                    |
Argo CD repositories
      |
      +------> GitOps model
                    |
Kafka / Security / Observability specialist repos
      |
      +------> Adapted Data Platform components
                    |
                    v
enterprise-data-lakehouse-kubernetes-openshift
```
