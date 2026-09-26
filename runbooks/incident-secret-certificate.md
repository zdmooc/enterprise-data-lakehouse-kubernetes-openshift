# Runbook — Secret / certificate / identity failure

## Signals
- authentication denied;
- TLS handshake failure;
- expired credential;
- workload cannot read required runtime secret.

## Triage
Inspect:
- Secret metadata/name only;
- ServiceAccount;
- Vault/identity binding;
- certificate issuer/expiry metadata;
- application error category.

Never paste secret values into evidence or Git.

## Remediation
- rotate/reissue through the authoritative secret backend;
- update binding/policy if authorization is wrong;
- restart/reconcile only the affected workload when required.

## Verify
- positive authentication works;
- unauthorized ServiceAccount remains denied;
- no secret material was captured in logs/evidence.
