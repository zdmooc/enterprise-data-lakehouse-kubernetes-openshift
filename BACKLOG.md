# Backlog

## P0 — Foundation

- [x] Initialize repository.
- [x] Define repository purpose and truth rules.
- [x] Write target architecture.
- [x] Write mission capability mapping.
- [x] Write reuse matrix.
- [x] Write lab resource strategy.
- [x] Define end-to-end Data Product.
- [x] Define ADR template.
- [x] Define evidence template.
- [x] Add cluster preflight contract.

## P1 — Kubernetes/OpenShift platform

- [x] Kubernetes target profile: KTHW/Vagrant.
- [x] OpenShift target profile: CRC.
- [ ] Execute connectivity/readiness preflight on target cluster.
- [ ] Validate cluster DNS with workload.
- [ ] Validate dynamic PVC write/read/restart.
- [ ] Validate namespace-scoped RBAC with negative test.
- [ ] Validate default-deny NetworkPolicy with allow exception.
- [x] Namespace/project baseline.
- [x] ResourceQuota.
- [x] LimitRange.
- [x] OpenShift SCC/PSS mapping.
- [x] ingress / route pattern for OpenShift workloads.
- [x] storage contract/profile abstraction; provider runtime validation pending.
- [x] expanded healthcheck script.

## P1 — GitOps

- [x] Argo CD bootstrap.
- [x] AppProject model.
- [x] ApplicationSet vs App-of-Apps ADR.
- [x] Helm conventions.
- [x] Kustomize overlays.
- [ ] Execute drift/self-heal demo on target cluster.
- [ ] Execute Git revert/rollback demo on target cluster.

## P1 — Data Platform

- [x] S3-compatible object-storage contract and zone layout; provider runtime pending.
- [x] Kafka / Strimzi implementation; runtime pending.
- [x] Spark implementation; runtime pending.
- [x] Trino implementation; runtime pending.
- [x] Jupyter implementation; runtime pending.
- [x] sample Data Product implementation; E2E runtime pending.

## P2 — Extended Data services

Only add when a use case requires them:

- [ ] MongoDB.
- [ ] OpenSearch.
- [ ] Redis.
- [ ] RabbitMQ.
- [ ] Flink.
- [x] Iceberg REST Catalog / Polaris reference implementation; runtime pending.

The repository must not become a tool catalogue.

## P1 — Security

- [x] OIDC identity architecture.
- [x] Keycloak/OIDC integration pattern; runtime integration pending.
- [x] Vault pattern.
- [x] Kyverno policies.
- [x] OPA Gatekeeper positioning/comparison.
- [x] Trivy scan command/workflow; runtime result pending.
- [ ] Grype comparison.
- [x] Cosign signing/verification design; signed artifact evidence pending.
- [ ] Falco runtime-security assessment.
- [ ] NeuVector positioning note.
- [ ] secret rotation scenario.

## P1 — Observability / N3

- [x] Prometheus/OpenShift user-workload metrics resources.
- [x] Grafana dashboard assets.
- [x] PrometheusRule alerts; Alertmanager routing remains platform-owned.
- [x] Loki/OpenShift logging strategy.
- [x] OpenSearch positioning.
- [x] platform health SLI/SLO.
- [x] Data pipeline SLI/SLO.
- [x] RCA template.
- [x] upgrade/migration strategy.
- [x] incident runbooks.

## P2 — Networking

- [ ] CNI concepts and current target implementation.
- [ ] Calico comparison.
- [ ] Cilium comparison.
- [ ] Canal positioning.
- [ ] BGP concepts and enterprise use.
- [ ] F5 north-south integration pattern.
- [x] deny-by-default egress plus explicit Data Product flows.

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
