# 02 — Mission Capability Alignment

## Context

This repository is a personal preparation and engineering lab aligned with a recruiter-described mission involving:

- Kubernetes / OpenShift;
- on-premise CaaS;
- GitOps;
- security;
- N3 support;
- monitoring/logging;
- and, importantly, support to **Data teams for the build and industrialization of Data products on Kubernetes and OpenShift**.

Public research suggested a possible organizational context around CA-GIP / Compute & Cloud Experience / Data & AI / Big Data. This is treated only as **contextual hypothesis**, not as confidential or official project information.

## Capability mapping

| Mission need | Repository response |
|---|---|
| Kubernetes/OpenShift architecture | platform profiles + HLD/LLD |
| CaaS on-premise | reusable cluster contract and platform baseline |
| Data-team enablement | Data Product path: Kafka → Spark → S3 → Trino → Jupyter |
| Argo CD | GitOps foundation |
| Helm | packaging conventions |
| Kustomize | environment overlays |
| RBAC | platform baseline |
| NetworkPolicies | zero-trust namespace baseline |
| SCC | OpenShift-specific security mapping |
| Kyverno / Gatekeeper | Policy-as-Code |
| Vault | secret-management pattern |
| Keycloak / OIDC | identity pattern |
| Prometheus / Grafana | metrics and dashboards |
| Alertmanager | alerting |
| Loki / OpenSearch | logs |
| upgrades | Day-2 lifecycle |
| N3 support | runbooks + RCA |
| Kafka | streaming layer |
| MinIO / S3 | lake/object-storage layer |
| Spark | distributed processing |
| Trino | SQL/query layer |
| Jupyter | Data user experience |
| MongoDB / Redis / RabbitMQ | optional use-case-driven extensions |
| Rancher / RKE2 | comparison/secondary profile |
| Calico / Cilium / BGP / F5 | networking workstream |
| Longhorn / Portworx / Trident | storage workstream |
| Trivy / Grype / Cosign | supply-chain security |
| Falco / NeuVector | runtime security assessment |
| Kubebuilder / Go | operator engineering workstream |

## Interview narrative

The intended narrative is:

1. understand Kubernetes internals;
2. operate OpenShift as an enterprise platform;
3. expose governed platform capabilities to Data teams;
4. industrialize deployment with GitOps;
5. run Data workloads with explicit resource, storage and network controls;
6. instrument everything;
7. support Day-2 and N3 scenarios.

This avoids presenting the profile as only an OpenShift administrator or only a Data engineer.
