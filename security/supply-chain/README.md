# Container / Software Supply Chain Security

## Current tool baseline

- Trivy: 0.74.0 is the latest stable release verified when this baseline was written.
- Cosign: 3.1.3 is the current release verified when this baseline was written.

## Pipeline target

```text
source
  -> secret scan
  -> IaC/Kubernetes scan
  -> dependency/image scan
  -> SBOM
  -> build
  -> sign
  -> verify
  -> GitOps
  -> admission policy
```

## Initial rules

- no `:latest` image tags;
- no secret material in Git;
- scan Kubernetes/Dockerfiles;
- images progressively pinned by digest;
- signed-image enforcement only after the signing identity/registry workflow is operational.

## Truth rule

A design for Cosign is not a signed artifact.
A Trivy command in CI is not a clean scan until the workflow executes successfully.
