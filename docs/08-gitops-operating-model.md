# 08 — GitOps Operating Model

## Objective

Use Git as the source of truth for platform and Data Product deployment while keeping bootstrap minimal and reversible.

## Control plane

- OpenShift: OpenShift GitOps / Argo CD in `openshift-gitops`.
- Kubernetes: Argo CD in `argocd`.
- One `AppProject` constrains repository and target namespaces.
- Initial applications are explicit `Application` resources.
- `ApplicationSet` is introduced only when real multi-environment or multi-cluster generators are justified.

See ADR-001.

## Repository roles

```text
gitops/control/
  AppProject and control-plane policy

gitops/apps/
  Argo CD Applications

platform/
  Kubernetes/OpenShift platform baseline

data-platform/
  Data services and Data Product workloads
```

## Kustomize convention

Use Kustomize for:
- platform baseline;
- Kubernetes/OpenShift differences;
- namespace/resource policy overlays;
- lightweight environment-specific configuration.

Rules:
1. reusable manifests live in a base;
2. target-specific changes live in overlays;
3. no copied full manifest when a patch is sufficient;
4. no secret values in patches;
5. CRC-only settings must be visibly labeled as lab settings.

## Helm convention

Use Helm primarily for upstream products with an official or maintained chart.

Rules:
1. pin chart version;
2. keep values in Git without credentials;
3. prefer vendor chart + local values over forked charts;
4. record compatibility assumptions;
5. use Argo CD multi-source only when it materially reduces duplication;
6. never use `latest` for production-like evidence.

## Environment model

The repository recognizes four logical stages:

```text
sandbox/dev -> build/test -> preprod-like -> prod-like
```

CRC is a single-node lab and does not prove these are physically separate environments.

Environment separation may later be implemented through:
- dedicated namespaces;
- dedicated clusters;
- separate repositories/branches only when governance requires it;
- ApplicationSet generators when multiple real targets exist.

The current repository does not fabricate multi-cluster evidence.

## Secrets strategy

Git contains:
- secret names;
- key names/contracts;
- Vault paths/examples;
- ServiceAccount bindings;
- External Secrets/Vault integration patterns when implemented.

Git never contains:
- passwords;
- access keys;
- private keys;
- kubeconfigs;
- tokens.

Current target pattern:

```text
Workload ServiceAccount
        |
Kubernetes auth
        |
      Vault
        |
least-privilege secret path
```

Static lab Secrets may be generated at runtime only and must not be committed.

## Reconciliation policy

Initial lab policy:
- automated sync;
- prune enabled;
- self-heal enabled.

For production-like environments, destructive synchronization must later be governed through review, sync windows and change controls.

## Promotion model

Promotion is configuration promotion, not image rebuilding:

```text
build once
   |
immutable image digest
   |
dev
   |
preprod
   |
prod
```

Application code/artifact identity must remain unchanged across promotion where possible.

## I3 runtime acceptance

I3 is runtime validated only after:
1. Argo CD/OpenShift GitOps is available;
2. `enterprise-data-lakehouse` AppProject exists;
3. `edl-platform-baseline` is Synced/Healthy;
4. controlled drift is detected and self-healed;
5. a Git change reconciles;
6. the Git change is reverted and Argo CD reconciles the rollback;
7. evidence is captured.
