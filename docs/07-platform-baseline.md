# 07 — Platform Baseline

## Objective

Provide a governed platform boundary before Data middleware is installed.

## Delivered

- `edl-platform`, `edl-data`, `edl-observability` namespaces;
- Pod Security labels;
- ResourceQuota;
- LimitRange;
- ServiceAccounts;
- namespace-scoped RBAC;
- default-deny ingress;
- default-deny egress;
- explicit DNS egress;
- Kubernetes and OpenShift Kustomize overlays.

## Apply

OpenShift:

```bash
bash scripts/apply-baseline.sh openshift
bash scripts/verify-baseline.sh
```

Kubernetes:

```bash
bash scripts/apply-baseline.sh kubernetes
bash scripts/verify-baseline.sh
```

## Security posture

The `edl-data` namespace starts with deny-by-default networking. Data services must add only the flows they require.

OpenShift SCC permissions are not granted broadly. SCC-specific additions are introduced only when a concrete workload requires them.

## Evidence

The baseline is implemented in Git. It becomes runtime validated only after execution on an actual target cluster with evidence.
