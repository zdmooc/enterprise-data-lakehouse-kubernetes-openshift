# GitOps Secrets Contract

## Rule

No secret value is stored in this repository.

Git may store only:
- Secret resource names/contracts without values;
- Vault paths;
- ServiceAccount references;
- External Secrets/Vault integration manifests that contain no credential;
- examples using placeholders.

## Target

```text
Git
 |
 | references only
 v
Argo CD
 |
 v
Workload ServiceAccount
 |
 v
Vault / enterprise secret backend
 |
 v
runtime credential
```

## CRC

For local-only tests, a secret may be generated imperatively at runtime.

It must:
- use synthetic credentials;
- be excluded from Git;
- be removable by cleanup scripts;
- never be presented as the production secret-management model.

See `security/vault/README.md`.
