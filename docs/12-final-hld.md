# I12 — High-Level Design

## Purpose

Reference platform for industrializing a synthetic enterprise Data Product on Kubernetes/OpenShift.

## Logical architecture

```text
                         Data User
                            |
                         Jupyter
                            |
                          Trino
                            |
                  Iceberg REST Catalog
                         Polaris
                            |
              +-------------+-------------+
              |                           |
            Spark                       S3
              |
            Kafka
              |
      Synthetic Transaction Producer
```

Cross-cutting services:

```text
GitOps        Security         Observability        N3
Argo CD       RBAC             Prometheus           Runbooks
Kustomize     NetworkPolicy    Grafana              RCA
Helm          SCC/PSS          Alerts               Evidence
              Vault/OIDC
```

## Platform zones

- `edl-platform`: platform control resources.
- `edl-data`: Data Product runtime.
- `edl-observability`: optional observability extensions.

## Architectural principles

1. Data Product drives platform choices.
2. S3 contract is provider-neutral.
3. Kafka is KRaft/Operator-managed where applicable.
4. Spark and Trino are independently smoke-tested before E2E integration.
5. Iceberg REST Catalog decouples engines from catalog implementation.
6. deny-by-default networking is retained; required flows are explicit.
7. no secrets in Git.
8. GitOps reconciles declared state.
9. CRC proves functional integration only.
10. multi-node HA/resilience is a separate evidence track.

## Runtime profiles

### OpenShift CRC
Functional development/demo profile.

### Kubernetes
Portability profile for generic Kubernetes concepts and workloads.

### Multi-node future target
Required for:
- node-loss;
- Kafka replication;
- storage failure domains;
- realistic HA/PDB;
- multi-node performance;
- upgrade/resilience evidence.
