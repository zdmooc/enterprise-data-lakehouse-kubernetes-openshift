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

Proceed to each next component only after deployment, readiness, tests, evidence
and resource checks pass. Remaining component commands are added as validated.

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
```

Open https://localhost:8443. Retrieve the initial administrator password locally
from the Kubernetes Secret; never paste it into evidence, documentation or Git.

## Troubleshooting and limitations

Initial image downloads occur separately inside node containerd and may take several
minutes. Inspect pod events before interpreting `ContainerCreating` as a failure.
Restricted PSS requires explicit non-root, seccomp, dropped capabilities and disabled
privilege escalation. Local-path PVC data is tied to one Kind node's storage.
CRC stop was observed clearing its managed kubeconfig contexts; the final switching
procedure must preserve and restore the Kind connection before it is called validated.

References: [Kind v0.29.0](https://github.com/kubernetes-sigs/kind/releases/tag/v0.29.0),
[Calico on Kind](https://docs.tigera.io/calico/latest/getting-started/kubernetes/kind),
[RustFS containers](https://docs.rustfs.com/en/installation/container).
