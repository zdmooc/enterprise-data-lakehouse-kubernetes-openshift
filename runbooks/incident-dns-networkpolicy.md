# Runbook — DNS / NetworkPolicy path failure

## Symptoms
- connection timeout;
- service name does not resolve;
- DNS resolves but TCP connection fails.

## Triage

```bash
oc -n edl-data get svc,endpoints
oc -n edl-data get networkpolicy
oc -n edl-data get pods -o wide
```

Test in this order:
1. DNS name resolution;
2. service/endpoints;
3. destination pod readiness;
4. NetworkPolicy source selector;
5. NetworkPolicy destination selector/port;
6. application protocol.

## Key rule
Do not disable default-deny globally to repair one flow.

Add or correct the narrowest required flow and capture the reason in Git.

## Verify
Negative paths remain denied while the required Data Product path succeeds.
