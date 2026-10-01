# Backlog

## Completed core POC

### Foundation
- [x] Repository purpose, truth rules and architecture.
- [x] Mission capability mapping and reuse strategy.
- [x] Data Product scenario and evidence rules.
- [x] Cluster contract and verification tooling.

### Kubernetes / platform
- [x] Three-node Kind runtime.
- [x] Cluster readiness and DNS validation.
- [x] Dynamic PVC write/read/persistence validation.
- [x] Namespace-scoped RBAC negative validation.
- [x] Default-deny NetworkPolicy and explicit allow flows.
- [x] Namespace, ResourceQuota and LimitRange baseline.
- [x] Security-context / PSS-aligned local profile.
- [x] Health checks and N3 diagnostics.

### GitOps
- [x] Argo CD bootstrap and AppProject/Application model.
- [x] Helm/Kustomize conventions.
- [x] Synced/Healthy runtime proof.
- [x] Controlled drift/self-heal proof.
- [x] Git-driven reconciliation / rollback pattern.

### Data Platform
- [x] S3-compatible object-storage runtime.
- [x] Kafka / Strimzi runtime.
- [x] Spark runtime and Iceberg transform.
- [x] Polaris REST catalog integration.
- [x] Trino runtime and Iceberg query.
- [x] Jupyter runtime and persistent workspace.
- [x] End-to-end Kafka -> Spark/Iceberg -> S3/Polaris -> Trino -> Jupyter proof.
- [x] Retained six-row I12 snapshot and exact event verification.

### Security
- [x] RBAC and deny-by-default network controls.
- [x] Kyverno policy runtime.
- [x] Five-case negative security suite.
- [x] Trivy-based hardening workflow.
- [x] Jupyter GitPython remediation.
- [x] Read-only root filesystem contracts.
- [x] Kind KSV-0014 findings reduced to zero.
- [x] H1 local hardening evidence.
- [x] Cosign design documented.
- [x] Vault and OIDC/Keycloak target patterns documented.

### Observability / operations
- [x] Prometheus monitoring resources.
- [x] Grafana dashboards.
- [x] PrometheusRule assets.
- [x] 21 configured scrape targets validated UP.
- [x] Grafana authenticated API/database health validated.
- [x] RCA template, incident runbooks and upgrade/migration strategy.
- [x] I11 functional recovery scenarios.
- [x] H2 Kind -> CRC -> Kind operational switching proof.

## Explicit residual scope

These items are useful future extensions, not blockers for the completed local POC.

### Security extensions
- [ ] Grype comparison.
- [ ] Signed-image admission enforcement.
- [ ] Falco runtime-security assessment.
- [ ] NeuVector positioning/runtime assessment.
- [ ] Vault runtime integration and secret rotation.
- [ ] OIDC/Keycloak runtime integration.

### Networking extensions
- [ ] Cilium comparison/runtime profile.
- [ ] Canal positioning.
- [ ] BGP enterprise pattern.
- [ ] F5 north-south integration pattern.

### Storage / resilience extensions
- [ ] Longhorn positioning/runtime profile.
- [ ] Portworx positioning/runtime profile.
- [ ] NetApp Trident positioning/runtime profile.
- [ ] CSI snapshots.
- [ ] Backup/restore proof.
- [ ] Multi-host storage failure injection.
- [ ] Durable Polaris metadata backend.

### Platform variants
- [ ] RKE2 architecture/runtime profile.
- [ ] Rancher management-plane note/runtime profile.
- [ ] Multi-node OpenShift target for HA-only scenarios.
- [ ] Operator/Kubebuilder hello-operator.
- [ ] Go fundamentals for operator maintenance.

## Definition of Done

A core POC capability is considered complete only when:
- design exists;
- code/manifests exist;
- a validation command exists;
- runtime evidence is captured;
- limitations are documented.

The completed local POC satisfies this definition for I1-I12 within its stated
single-workstation scope.
