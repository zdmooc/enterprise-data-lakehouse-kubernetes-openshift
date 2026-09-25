# I9 — Security & Secrets

## Implemented baseline

- Kubernetes/OpenShift RBAC and negative tests;
- SCC/PSS mapping;
- namespace NetworkPolicies;
- Kyverno CEL policies;
- Vault integration architecture;
- OIDC/Keycloak identity model;
- Trivy configuration scan;
- Cosign/signature architecture.

## Current versions verified at design time

- Kyverno 1.19.1
- Vault Helm chart 0.34.1 / Vault 2.0.4
- Trivy 0.74.0
- Cosign 3.1.3

## Kyverno

Kyverno 1.19 deprecates legacy `ClusterPolicy` / `Policy`.

This repository therefore uses:

`policies.kyverno.io/v1`

Install and test:

```bash
bash scripts/install-kyverno.sh
bash scripts/apply-security-policies.sh
bash scripts/test-security-policies.sh
```

## Vault

Vault is an integration workstream, not a committed static-secret store.

See `security/vault/README.md`.

## Supply chain

Run:

```bash
bash scripts/security-scan.sh
```

Image signing/verification is not marked implemented until a registry identity and signed image evidence exist.

## Gatekeeper

OPA Gatekeeper remains a comparison/interop topic because Kyverno is the selected lab policy engine. Installing two admission engines without a use case would add operational complexity, not evidence.
