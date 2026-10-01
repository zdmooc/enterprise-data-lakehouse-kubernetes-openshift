# I11 — KIND_MULTI_NODE_FUNCTIONAL_RECOVERY

Status: **RUNTIME_VALIDATED**, scoped to the seven scenarios below.
Execution dates: 2026-09-29 and 2026-09-30 UTC. The session resumed on September 30;
these are individual observations, not one continuous availability measurement.

## Preconditions recorded before the first action

The requested `git status`, `git branch --show-current`, `git log --oneline -5`,
`kubectl config current-context`, `kubectl get nodes -o wide`, and
`kubectl get pods -A` were run before failure injection.

- Clean branch `runtime/kind-edl-lab`, synchronized with origin.
- Starting HEAD: `e4137cb29274a5d738f4ba1dc8da617df64a1154`.
- Last five commits: `e4137cb`, `266e9c3`, `8076fc9`, `1aea523`, `ccbb114`.
- Context: `kind-edl-lab`; all three nodes Ready, Kubernetes v1.33.1.
- Existing service pods Running/Ready; completed batch pods retained.
- I1-I10 were acquired gates, not rerun. I12 was not executed.

## Ordered scenarios and evidence

Each log records BEFORE, the action, a bounded WAIT, AFTER, functional assertions,
and its result. Pod replacement requires a different UID and a Ready condition.
Readiness durations below are measured to that condition, not complete service RTOs.

| Order | Scenario | Observed result | Evidence |
|---|---|---|---|
| 1 | Jupyter pod replacement | Ready in 17.0 s; same PVC UID/volume Bound; existing marker retained; SELECT 1 and exactly five Iceberg transactions | [jupyter.txt](jupyter.txt) |
| 2 | Trino worker replacement | Ready in 64.9 s; coordinator unchanged/Ready in 15 samples during wait; SELECT 1 and five transactions after recovery | [trino.txt](trino.txt) |
| 3 | Kafka broker/controller replacement | Ready in 27.7 s; same Bound PVC; controller leader 0; topic retained; fresh unique event produced/consumed at offset 2 in edl.smoke | [kafka.txt](kafka.txt) |
| 4 | Polaris replacement and reconstruction | Ready in 27.0 s, but catalog list became empty and SQL failed with SCHEMA_NOT_FOUND; resume-data restored the catalog and exactly five transactions from retained Kafka | [polaris.txt](polaris.txt), [spark-lakehouse.txt](spark-lakehouse.txt) |
| 5 | RustFS pod replacement | Ready in 9.0 s; same Bound PVC; all 15 prior keys/sizes/ETags retained; fresh PUT/GET/integrity/LIST/DELETE/absence checks and SQL passed | [s3.txt](s3.txt) |
| 6 | Argo self-heal | Changed only requests.cpu quota from 6 to 7; observed OutOfSync/Healthy, then automatic restoration to 6 and Synced/Healthy in 10.2 s; automated operation Succeeded; SQL passed | [argo.txt](argo.txt) |
| 7 | N3 diagnostics | Existing n3-diagnostics.sh plus nodes/pods/events/storage/network/Argo snapshots; DNS, PVC marker and SQL passed; all nodes Ready, all pods healthy/completed, all PVCs Bound, both applications Synced/Healthy | [diagnostics.txt](diagnostics.txt) |

## Failures and corrections retained in the logs

Polaris lost its in-memory catalog as expected. This is an actual loss of metadata,
not transparent failover. The first reconstruction attempt also encountered an
occupied local port 18181, owned by a pre-existing Kind Polaris port-forward
(process 25384). Its authentication request ended in RemoteDisconnected. The
bootstrap helper now selects an available loopback port and checks its forwarding
process. Reconstruction then succeeded without a second Polaris pod deletion.
The pre-existing port-forward process was not terminated.

The S3 harness first failed before deleting the server pod because Windows text
stdin converted LF to CRLF. Binary UTF-8 stdin preserves the Linux script's LF.
After the actual replacement, the first fresh-object assertion incorrectly assumed
RustFS returned KeyCount. This response omits that field. The final assertion counts
the actual Contents array (empty/missing means zero); a fresh object was uploaded,
read byte-for-byte, listed, deleted, and confirmed absent. The earlier failures and
the successful final run are retained. RustFS was replaced only once.

The first N3 invocation used the installed oc client against the current Kind
context. Git Bash PATH precedence was then fixed inside Bash to select the existing
Kind adapter, which pins every call to kind-edl-lab. Diagnostics were rerun with
that adapter. No CRC context or CRC command was used.

## Limits and N3 observations

- Three Kind nodes share one Windows laptop and Docker/WSL infrastructure. Only
  pod/process replacement was injected, not host, node, disk, zone or network loss.
- Stateful replacement reused local PVCs on the same nodes. Kafka has one combined
  broker/controller and replication factor one; interruption is expected.
- **Polaris durability is NOT VALIDATED.** Catalog/table reconstruction requires
  retained Kafka data and existing S3 storage. It is not restoration from a durable
  Polaris catalog backup. Old Iceberg objects may remain after reconstruction.
- N3 captured probe/API timeouts around 2026-09-30 04:52 UTC, before the final S3,
  Argo and N3 runs. Strimzi's restart count was 4, versus 2 at initial preflight.
  The operator was Ready in the final snapshot. Controller-manager and scheduler
  remained at the previously recorded 5 restarts each. The underlying cause of
  those transient timeouts is not established, and is not attributed to a scenario.
- Kubernetes events have finite retention; the final N3 snapshot is dated separately
  from September 29's replacements. Per-scenario UID logs retain their own evidence.
- No PVC, namespace or cluster deletion, no Docker prune, no CRC operation. Only
  the completed lakehouse job/driver were recreated by the documented reconstruction
  procedure. The smoke event was not added to transactions.raw; I12 remains NOT_TESTED.

## Reproduction and publication checks

Run `bash scripts/kind/recovery.sh` only when these seven replacements are intended
and the lab contains the original five-transaction fixture. Optional scenario names
are `jupyter`, `trino`, `kafka`, `polaris`, `s3`, `argo`, `diagnostics`.
After an interrupted reconstruction, `polaris-resume` continues without another
Polaris deletion; `s3-contract` resumes functional checks after recorded replacement.
Logs append so failed attempts remain visible. Reconstruction writes its Spark log
under this I11 directory, preserving the acquired I6 evidence.

Publication checks are recorded in [verification.txt](verification.txt). No Secret
manifests are exported. Live lab credential comparison and token/private-key pattern
checks complement the restricted diagnostics output; they are not a universal
sensitive-data detection guarantee.
