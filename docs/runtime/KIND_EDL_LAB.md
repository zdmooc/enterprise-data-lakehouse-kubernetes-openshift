# Enterprise Data Lakehouse — Kind lab

This profile runs on Windows 11, Git Bash and Docker Desktop (Linux containers).
Run commands from the repository root in Git Bash. Runtime validation is recorded
in `evidence/kind-edl-lab/`; implemented files alone do not establish runtime success.

## Source and isolation

The runtime branch `runtime/kind-edl-lab` starts at audited revision
`ccbb114fb219a4d58d668be3717116670c4bc081`. Audit PR #2 remains unmerged.
The older `main` revision is not used as the runtime source. Existing OpenShift
profiles remain separate. No Route, SCC, BuildConfig or ImageStream is deployed here.

Every Kind deployment script checks `kind-edl-lab` and passes that context explicitly.
Portable legacy tests use a separate ignored kubeconfig containing only this lab.
CRC is stopped before running Kind; CRC workloads must never be modified by this lab.

## Architecture and prerequisites

Kind v0.29.0 creates Kubernetes v1.33.1 with one control-plane and two workers.
The node image is pinned by digest in `platform/kind/kind-edl-lab.yaml`.
Calico v3.30.3 enforces NetworkPolicy; the default Kind CNI is disabled.
Docker Desktop has 8 CPUs and approximately 32 GiB available on the validation host.
Kind node containers share that capacity; their reported limits are not additive.
No per-node CPU or RAM guarantee is implied.

The intended chain is synthetic events → Kafka → Spark → Iceberg/S3 → Polaris
→ Trino → Jupyter. Argo CD manages the Kind GitOps applications. Observability
uses upstream Prometheus/Grafana instead of OpenShift User Workload Monitoring.
Local storage uses Kind's local-path StorageClass. Three containers on one laptop
do not demonstrate multi-host HA, multi-AZ resilience or disaster recovery.

## Bootstrap order

1. `bash scripts/kind/create-edl-lab.sh`: create nodes and Calico; require three Ready nodes.
2. `bash scripts/kind/preflight.sh`: run I1 DNS, PVC, RBAC and real NetworkPolicy probes.
3. `bash scripts/kind/baseline.sh`: namespaces, quotas, RBAC, restricted PSS, network rules.
4. `bash scripts/kind/test-contract.sh`: verify DNS and durable PVC data under the baseline.
5. `bash scripts/kind/argocd.sh`: install upstream Argo CD chart 10.9.2.
6. `bash scripts/kind/gitops.sh`: synchronize baseline/networking and verify self-healing.
7. `bash scripts/kind/s3.sh`: local RustFS, four zones, real PUT/GET/LIST/DELETE contract.
8. `bash scripts/kind/kafka.sh`, then `bash scripts/kind/test-kafka.sh`: Strimzi, topics, producer/consumer.
9. `bash scripts/kind/build-spark.sh`, then `bash scripts/kind/spark.sh smoke`: Docker build/load and distributed Pi job.
10. `bash scripts/kind/polaris.sh`, then `bash scripts/kind/spark.sh lakehouse`: REST catalog and Kafka-to-Iceberg batch.
11. `bash scripts/kind/trino.sh`: SQL, TPCH, actual Iceberg rows.
12. `bash scripts/kind/jupyter.sh`: build/load, authenticated HTTP, SQL and persistent workspace.
13. `bash scripts/kind/security.sh`, then `bash scripts/kind/supply-chain.sh`: admission/RBAC denials and Trivy reports.
14. `bash scripts/kind/monitoring.sh`: Prometheus targets/rules and Grafana dashboards.
15. `bash scripts/kind/recovery.sh`: N3 diagnostics and controlled Kind pod replacement.
16. `bash scripts/e2e-lakehouse-kind.sh`: fresh event verified in Trino and Jupyter, with S3 files.
17. `bash scripts/kind/collect-evidence.sh`: final inventory and resource snapshots.

Proceed to each next component only after deployment, readiness, tests, evidence
and resource checks pass. Use the dated evidence summary for actual gate status.
These commands require Git Bash, Docker, Kind, kubectl, Helm, OpenSSL and Python 3.
Set `EDL_PYTHON` if Python is not on PATH and the bundled Windows runtime is unavailable.
The supply-chain script expects checksum-verified Trivy 0.74.0 at
`.audit/kind/trivy/trivy.exe`; it never treats a completed scan as zero vulnerabilities.
Secrets are generated locally and supplied through Kubernetes Secrets. `.audit/` is
ignored and must not be published. Review sanitized reports before committing evidence.

The data namespace quota permits requests up to 6 CPUs/16 GiB and limits up to
16 CPUs/24 GiB. This is namespace admission accounting, not physical capacity.
`kubectl top` requires metrics-server; until installed, the script explicitly reports
metrics unavailable and records `docker stats --no-stream` and `docker system df`.

## Lifecycle

```bash
bash scripts/kind/status-edl-lab.sh
bash scripts/kind/stop-edl-lab.sh
bash scripts/kind/start-edl-lab.sh
# Destructive, only when deliberately requested:
CONFIRM_DELETE_EDL_LAB=yes bash scripts/kind/delete-edl-lab.sh
```

Stop only stops the three containers selected by the Kind cluster label. Data and
containers are retained. Delete removes this Kind cluster and its local storage.
No script prunes Docker or deletes CRC.

## Access

Use explicit Kind context and localhost port forwarding:

```bash
kubectl --context=kind-edl-lab -n argocd port-forward svc/argocd-server 8443:443
kubectl --context=kind-edl-lab -n edl-data port-forward svc/edl-trino 8080:8080
kubectl --context=kind-edl-lab -n edl-data port-forward svc/edl-jupyter 8888:8888
kubectl --context=kind-edl-lab -n edl-observability port-forward svc/edl-monitoring-prometheus 9090:9090
kubectl --context=kind-edl-lab -n edl-observability port-forward svc/edl-monitoring-grafana 3000:80
```

Open https://localhost:8443. Retrieve the initial administrator password locally
from the Kubernetes Secret; never paste it into evidence, documentation or Git.
Run each port-forward in a separate terminal. Trino, Jupyter, Prometheus and Grafana
use HTTP on the forwarded localhost ports. Jupyter's token is the `token` key of
`edl-data/jupyter-auth`; Grafana credentials are in
`edl-observability/kind-grafana-admin`. Retrieve them privately on the workstation.

## Restart and CRC switching

The Polaris catalog is **LAB ONLY, NOT DURABLE, NOT PRODUCTION HA**. Kafka and S3
have local PVCs, but Polaris uses an in-memory metadata store. The start script waits
for deployments, re-establishes catalog grants, replays retained Kafka records with
the existing Spark batch job and checks Jupyter SQL. This reconstructs the lab table;
it is not a durable catalog backup, continuous streaming or exactly-once processing.
Retained Kafka history is required for reconstruction. Old S3 snapshots can remain.

Only perform switching after current jobs finish:

```bash
# Kind -> CRC: no CRC workload writes
bash scripts/kind/stop-edl-lab.sh
crc start
kubectl config use-context crc-admin
kubectl --context=crc-admin get nodes

# CRC -> Kind
crc stop
bash scripts/kind/start-edl-lab.sh
bash scripts/e2e-lakehouse-kind.sh
```

`crc stop` was observed removing kubeconfig contexts. The start script uses
`kind export kubeconfig --name edl-lab` before selecting the Kind context.
Keep Docker Desktop running during the switch. Stopping is reversible; deleting
the cluster destroys its local PVC data. The delete command above is documented
for a deliberate future user decision and is not part of validation.

## Kind and OpenShift boundaries

| Concern | Kind lab | Existing OpenShift profile |
| --- | --- | --- |
| Images | Docker build and Kind import | BuildConfig/ImageStream paths retained |
| Exposure | Localhost port-forward | Routes retained |
| Identity | Explicit non-root UID, restricted PSS | SCC/arbitrary UID profiles retained |
| GitOps | Upstream Argo CD, Kind-only project | OpenShift GitOps profile retained |
| Monitoring | Upstream kube-prometheus-stack | User Workload Monitoring retained |
| Storage | local-path, single-laptop failure domain | Existing platform storage configuration |

Kafka has one dual-role broker/controller and replication factor one. RustFS,
Polaris, Trino coordinator and Jupyter are single instances. Pod recovery tests
demonstrate `KIND_MULTI_NODE_FUNCTIONAL_RECOVERY`, not production HA or PRA.
Network access and authentication are scoped for a local development lab.

## Troubleshooting and limitations

Initial image downloads occur separately inside node containerd and may take several
minutes. Inspect pod events before interpreting `ContainerCreating` as a failure.
Restricted PSS requires explicit non-root, seccomp, dropped capabilities and disabled
privilege escalation. Local-path PVC data is tied to one Kind node's storage.
Spark's official image provides `python3`; the image build must invoke that binary.
ConfigMap mounts in Spark pod templates use native pod YAML, because Spark's generic
volume configuration does not accept `configMap` as a volume type. Load a new image
onto all three nodes before starting a job. Inspect failed driver logs before retrying.
Use `kubectl --context=kind-edl-lab -n edl-data get events --sort-by=.lastTimestamp`
and targeted pod logs to diagnose failures. Never export Secret YAML into evidence.
Prometheus target success and loaded rules do not prove all alert conditions fired.
Node exporter and control-plane integrations that require host privileges are disabled.
Kind's Trino ServiceMonitors use `basicAuth` with a username-only Secret reference;
the installed ServiceMonitor CRD rejects `httpHeaders`. A live probe returned HTTP
200 with username-only Basic authentication and 401 without an identity, matching
the [Trino OpenMetrics authentication example](https://trino.io/docs/current/admin/openmetrics.html).
This is the lab's existing unauthenticated-user mode, not password authentication.
The Operator requires an explicit Secret selector for the empty password as well.
`configure-trino-metrics.sh` supplies both keys, and `monitoring.sh` preserves them
on reruns. The Kafka broker PodMonitor selects only `edl-kafka-kafka`; the exporter
has its own monitor to avoid duplicate collection.

I10 runtime validation on 2026-09-29 found 21/21 configured targets UP, four healthy
loaded application rules, Grafana's authenticated API and healthy Prometheus
datasource, and both dashboards. Consumer-lag and PVC-capacity metric series were
absent; their dependent panels/alerts are not validated. No alert firing test or
metric coverage for unlisted components is claimed. `kubectl top = NOT AVAILABLE`;
Docker stats do not replace the Kubernetes Metrics API.

References: [Kind v0.29.0](https://github.com/kubernetes-sigs/kind/releases/tag/v0.29.0),
[Calico on Kind](https://docs.tigera.io/calico/latest/getting-started/kubernetes/kind),
[RustFS containers](https://docs.rustfs.com/en/installation/container).
