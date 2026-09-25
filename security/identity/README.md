# Identity / OIDC / Keycloak Pattern

## Separation of identities

The platform distinguishes:

- human Data users;
- platform administrators;
- GitOps controller;
- Spark jobs;
- Kafka clients;
- Trino/Jupyter users;
- observability components.

## Target enterprise flow

```text
Enterprise IdP / Active Directory
          |
        OIDC
          |
   Keycloak / IdP bridge
          |
   Kubernetes/OpenShift groups
          |
         RBAC
```

Application-level identity remains separate from Kubernetes RBAC.

## Lab strategy

Existing Keycloak/OIDC assets in the portfolio are reused rather than duplicated.

I9 focuses on:
- group-to-role mapping;
- service-account least privilege;
- negative authorization tests;
- OIDC architecture for Trino/Jupyter.

No claim is made that a customer uses Keycloak internally.
