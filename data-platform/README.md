# Data Platform Workstream

Initial implementation order:

```text
MinIO/S3
   |
Kafka/Strimzi
   |
Spark
   |
Trino
   |
Jupyter
```

This is an implementation sequence, not a mandatory runtime dependency chain.

Each component must provide:
- architecture note;
- Kubernetes/OpenShift deployment path;
- GitOps ownership;
- resources;
- storage;
- network;
- security;
- metrics/logs;
- smoke tests;
- cleanup;
- evidence.
