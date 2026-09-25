# Observability Workstream

Target:
- Prometheus;
- Grafana;
- Alertmanager;
- Loki and/or OpenSearch;
- Kubernetes/OpenShift events;
- Data-pipeline SLIs/SLOs.

Questions the platform must answer:
- Is the cluster healthy?
- Is ingestion alive?
- Is Kafka lag increasing?
- Did Spark processing complete?
- Is object storage reachable?
- Are Trino queries failing?
- Are workloads throttled or OOMKilled?
