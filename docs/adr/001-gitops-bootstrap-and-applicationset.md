# ADR-001 — GitOps bootstrap and ApplicationSet strategy

- Status: Accepted for lab implementation
- Date: 2026-09-25

## Context

The platform must work on both Kubernetes and OpenShift and later scale from one local cluster to multiple environments/clusters.

## Decision

Use:
1. a small imperative bootstrap only to install/detect Argo CD/OpenShift GitOps and apply the first control resources;
2. AppProject to constrain source repository and destinations;
3. Application for the initial platform baseline;
4. ApplicationSet progressively when Data components and multiple environments/clusters appear.

## Why not make everything ApplicationSet immediately?

The current lab has one active runtime target at a time. Introducing generators before there are multiple concrete targets adds complexity without evidence.

## Namespace mapping

- Kubernetes vanilla: `argocd`
- OpenShift GitOps: `openshift-gitops`

Kustomize overlays adapt control-plane resources to the correct namespace.

## Repository ownership

Argo CD source of truth:

`https://github.com/zdmooc/enterprise-data-lakehouse-kubernetes-openshift.git`

## Sync policy

Initial automated sync:
- prune: true;
- selfHeal: true.

Destructive changes and production promotion patterns will later introduce stronger controls.

## Validation

I3 is runtime validated only after:
- Argo CD/OpenShift GitOps is available;
- baseline Application becomes Synced/Healthy;
- manual drift is reverted;
- a Git change is reconciled;
- rollback/revert is demonstrated.

## Revisit triggers

- multi-cluster target becomes active;
- separate dev/preprod/prod clusters exist;
- fleet-scale onboarding requires ApplicationSet generators.
