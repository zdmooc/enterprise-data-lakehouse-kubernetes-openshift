# I2 — Platform Baseline

Portable baseline for Kubernetes and OpenShift.

## Provides

- namespaces/projects logical zones;
- service accounts;
- ResourceQuota;
- LimitRange;
- namespace-scoped RBAC;
- default-deny NetworkPolicy;
- DNS egress exception;
- PSS labels for vanilla Kubernetes portability.

## Apply

Vanilla Kubernetes:

```bash
kubectl apply -k platform/baseline/overlays/kubernetes
```

OpenShift:

```bash
oc apply -k platform/baseline/overlays/openshift-crc
```

## Validate

```bash
bash scripts/validate-baseline.sh
```

## Cleanup

```bash
bash scripts/cleanup-baseline.sh
```

## OpenShift note

OpenShift SCC remains authoritative for admission/security behavior. PSS labels are retained to keep the portable intent visible, but SCC/PSS differences must be validated explicitly.

ResourceQuota values are **lab defaults**, not production sizing.
