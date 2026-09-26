# Environment Strategy

The repository models environment promotion without pretending that a single CRC node is multiple production environments.

## Logical flow

```text
dev -> preprod-like -> prod-like
```

At the current lab stage:
- OpenShift CRC is the active OpenShift execution target;
- vanilla Kubernetes is a portability target;
- no fake dev/preprod/prod clusters are created.

When multiple real targets exist, this directory may host:
- ApplicationSet generators;
- environment parameter files;
- cluster selectors;
- promotion policy.

Until then, explicit Applications remain easier to audit and troubleshoot.

## Required invariants

Across environments:
- image is promoted by immutable digest;
- configuration differences are declarative;
- secrets come from an external/runtime source;
- resource sizing can differ;
- security policy cannot silently weaken;
- rollback is performed through Git state reconciliation.
