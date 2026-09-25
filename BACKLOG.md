# Backlog

## P0 — Foundation

- [x] Initialize repository.
- [x] Define repository purpose and truth rules.
- [ ] Write target architecture.
- [ ] Write mission capability mapping.
- [ ] Write reuse matrix.
- [ ] Write lab resource strategy.
- [ ] Define end-to-end Data Product.
- [ ] Define ADR template.
- [ ] Define evidence template.
- [ ] Add cluster preflight contract.

## P1 — Kubernetes/OpenShift platform

- [ ] Kubernetes target profile: KTHW/Vagrant.
- [ ] OpenShift target profile: CRC.
- [ ] Namespace/project baseline.
- [ ] ResourceQuota.
- [ ] LimitRange.
- [ ] RBAC.
- [ ] default-deny NetworkPolicy.
- [ ] OpenShift SCC/PSS mapping.
- [ ] ingress / route abstraction.
- [ ] CSI/storage abstraction.
- [ ] healthcheck script.

## P1 — GitOps

- [ ] Argo CD bootstrap.
- [ ] AppProject model.
- [ ] ApplicationSet vs App-of-Apps ADR.
- [ ] Helm conventions.
- [ ] Kustomize overlays.
- [ ] drift demo.
- [ ] rollback demo.

## P1 — Data Platform

- [ ] MinIO.
- [ ] Kafka / Strimzi.
- [ ] Spark.
- [ ] Trino.
- [ ] Jupyter.
- [ ] sample Data Product.

## P2 — Extended Data services

Only add when a use case requires them:

- [ ] MongoDB.
- [ ] OpenSearch.
- [ ] Redis.
- [ ] RabbitMQ.
- [ ] Flink.
- [ ] Iceberg catalog/metastore option.

The repository must not become a tool catalogue.

## P1 — Security

- [ ] OIDC.
- [ ] Keycloak lab integration.
- [ ] Vault pattern.
- [ ] Kyverno policies.
- [ ] OPA Gatekeeper comparison.
- [ ] Trivy scan.
- [ ] Grype comparison.
- [ ] Cosign signing/verification.
- [ ] Falco runtime-security assessment.
- [ ] NeuVector positioning note.
- [ ] secret rotation scenario.

## P1 — Observability / N3

- [ ] Prometheus metrics.
- [ ] Grafana dashboards.
- [ ] Alertmanager.
- [ ] Loki.
- [ ] OpenSearch positioning.
- [ ] platform health SLI/SLO.
- [ ] Data pipeline SLI/SLO.
- [ ] RCA template.
- [ ] upgrade checklist.
- [ ] incident runbooks.

## P2 — Networking

- [ ] CNI concepts and current target implementation.
- [ ] Calico comparison.
- [ ] Cilium comparison.
- [ ] Canal positioning.
- [ ] BGP concepts and enterprise use.
- [ ] F5 north-south integration pattern.
- [ ] egress control.

## P2 — Storage

- [ ] Longhorn positioning.
- [ ] Portworx positioning.
- [ ] NetApp Trident positioning.
- [ ] snapshots.
- [ ] backup/restore.
- [ ] performance classes.
- [ ] S3/object-storage lifecycle.

## P2 — Rancher/RKE2

- [ ] RKE2 architecture note.
- [ ] Rancher management-plane note.
- [ ] deployment profile decision.
- [ ] compare with OpenShift lifecycle and governance.

## P2 — Operators / Go

- [ ] Operator pattern.
- [ ] CRD/controller reconciliation concepts.
- [ ] Kubebuilder hello-operator.
- [ ] Go fundamentals required for operator maintenance.

## Definition of Done

A technical item is done only when:
- design exists;
- code/manifests exist;
- validation command exists;
- result is captured under `evidence/`;
- limitations are documented.
