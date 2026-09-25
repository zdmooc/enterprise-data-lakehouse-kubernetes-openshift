# I3 — GitOps Foundation

## Strategy

Bootstrap as little as possible imperatively, then let Argo CD/OpenShift GitOps own the platform state.

Architecture decision: [ADR-001](../docs/adr/001-gitops-bootstrap-and-applicationset.md).

## OpenShift CRC

Install/verify OpenShift GitOps:

```bash
bash scripts/install-openshift-gitops.sh
```

Bootstrap this repository:

```bash
bash scripts/bootstrap-gitops.sh
```

## Kubernetes

Install Argo CD through the dedicated Argo CD specialist repository/process, then:

```bash
bash scripts/bootstrap-gitops.sh
```

## Initial ownership

Argo CD owns the platform baseline through:

`edl-platform-baseline`

Source:
`platform/baseline/overlays/<profile>`

## Runtime validation required

I3 becomes runtime validated only after:
1. Application = Synced/Healthy;
2. manual drift is created;
3. self-heal restores Git state;
4. a Git change is reconciled;
5. a Git revert demonstrates rollback.

ApplicationSet is deferred until multiple concrete Data components/environments justify generators.
