# I10 — Observability

## OpenShift principle

On OpenShift, reuse the supported cluster monitoring stack first.

For user workloads, OpenShift User Workload Monitoring provides Prometheus Operator, Prometheus user workload and Thanos Ruler when `enableUserWorkload: true` is enabled by a cluster administrator.

This repository does not deploy a competing Prometheus stack on CRC by default.

## Metrics

### Kafka

Strimzi Metrics Reporter is enabled in the CRC Kafka profile and Kafka Exporter is enabled for topic/consumer-group metrics.

A PodMonitor is provided:

`openshift/kafka-podmonitor.yaml`

### Trino

Trino 480+ exposes OpenMetrics at `/metrics`.

Coordinator and worker ServiceMonitors are provided:

`openshift/trino-servicemonitors.yaml`

### Kubernetes/OpenShift

Platform alerts use kube-state/kubelet metrics exposed by the cluster monitoring stack.

## Alerts

`openshift/prometheus-rules.yaml`

Initial alerts cover:
- Kafka consumer lag;
- under-replicated Kafka partitions;
- repeated pod restarts;
- PVC free capacity.

Thresholds are lab defaults and require workload-specific tuning.

## Grafana

A portable dashboard asset is available in:

`grafana/edl-overview-dashboard.json`

The dashboard does not imply a standalone Grafana deployment. In an enterprise environment, use the organization's supported visualization service and datasource/authentication pattern.

## Alertmanager

Alert routing remains a platform concern. PrometheusRule resources define the alerts; notification routing is not hard-coded into the public repository.

## Logs

See `logging/README.md`.

## CRC validation

Run:

```bash
bash scripts/check-openshift-user-workload-monitoring.sh
bash scripts/apply-observability-openshift.sh
bash scripts/test-observability-openshift.sh
```

Do not enable User Workload Monitoring automatically on a shared/production cluster without platform approval.
