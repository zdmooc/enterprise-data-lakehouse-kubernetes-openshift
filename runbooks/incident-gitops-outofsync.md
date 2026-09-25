# Runbook — Argo CD OutOfSync / Sync Failure

## Signal

Application is OutOfSync, Degraded, Unknown or stuck Progressing.

## Triage

```bash
oc -n openshift-gitops get application
oc -n openshift-gitops get application edl-platform-baseline -o yaml
oc -n openshift-gitops logs deployment/openshift-gitops-application-controller --tail=200
```

## Questions

1. Can Argo CD reach the Git repository?
2. Does the path/revision exist?
3. Does Kustomize/Helm render locally?
4. Is a CRD missing?
5. Is admission policy denying a resource?
6. Is the destination namespace permitted by AppProject?
7. Is live drift intentional or accidental?

## Rule

Do not fix persistent GitOps drift only with `oc edit`.

The durable correction must be:
- Git change; or
- explicit approved exception.

## Validation

- sync = Synced;
- health = Healthy;
- manual drift self-heals;
- Git revert restores previous desired state.
