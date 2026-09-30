#!/usr/bin/env bash
# H2: stop retained Kind node containers, inspect CRC read-only, then restore Kind.
# No cluster deletion, no namespace/PVC deletion, no Kafka publish, no E2E replay.
set -Eeuo pipefail

source "$(dirname "$0")/common.sh"

BRANCH="runtime/kind-edl-lab"
H2_DIR="$EVIDENCE_DIR/h2-kind-crc-kind"
I12_EVENT="E2E-I12-20260930T051236Z-a0adb24c8c95"
mkdir -p "$H2_DIR"

KIND_STOPPED=false
CRC_MAYBE_RUNNING=false
SUCCESS=false
nodes=()
restart_order=()
declare -A expected_docker_ip

restore_kind_on_exit() {
  local code=$?
  if [ "$SUCCESS" = true ]; then
    return 0
  fi
  echo "[WARN] H2 interrupted/failed; attempting to leave Kind available" >&2
  if [ "$CRC_MAYBE_RUNNING" = true ]; then
    crc stop >/dev/null 2>&1 || true
  fi
  if [ "$KIND_STOPPED" = true ] && [ "${#restart_order[@]}" -eq 3 ]; then
    for node in "${restart_order[@]}"; do
      docker start "$node" >/dev/null 2>&1 || true
      sleep 2
    done
    kind export kubeconfig --name "$CLUSTER" >/dev/null 2>&1 || true
    kubectl config use-context "$CONTEXT" >/dev/null 2>&1 || true
  fi
  return "$code"
}
trap restore_kind_on_exit EXIT

echo "===== H2 PRECHECK ====="
[ "$(git branch --show-current)" = "$BRANCH" ] || fail "wrong Git branch"
DIRTY="$(git status --porcelain | grep -v "?? $H2_DIR/" || true)"
[ -z "$DIRTY" ] || fail "Git working tree has changes outside the H2 evidence directory"
guard

for cmd in docker kind kubectl crc; do
  command -v "$cmd" >/dev/null 2>&1 || fail "$cmd not found"
done

grep -Fq 'H1 local finalizer: PASS' "$EVIDENCE_DIR/h1-security-hardening/verification.txt" \
  || fail "H1 local PASS evidence is required before H2"

crc_state="$(crc status 2>&1 || true)"
if printf '%s\n' "$crc_state" | grep -Eq 'CRC VM:.*Running|OpenShift:.*Running'; then
  fail "CRC is already running; H2 requires the retained Kind runtime as the start state"
fi

mapfile -t nodes < <(lab_nodes)
[ "${#nodes[@]}" -eq 3 ] || fail "expected exactly 3 existing edl-lab node containers"
[ "$(docker ps -q --filter 'label=io.x-k8s.kind.cluster=edl-lab' | wc -l | tr -d ' ')" -eq 3 ] \
  || fail "all 3 edl-lab containers must be running before H2"

# Capture the exact Docker IP mapping before the switch. Kind node identities
# retain their InternalIP across a container stop/start, so the existing node
# containers must reacquire the same Docker bridge addresses on restart.
tmp_order="$(mktemp)"
for id in "${nodes[@]}"; do
  name="$(docker inspect -f '{{.Name}}' "$id" | sed 's#^/##')"
  ip="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$id")"
  [ -n "$ip" ] || fail "missing Docker IP for $name"
  expected_docker_ip["$name"]="$ip"
  printf '%s %s\n' "$ip" "$name" >> "$tmp_order"
done
mapfile -t restart_order < <(sort -V "$tmp_order" | awk '{print $2}')
rm -f "$tmp_order"
[ "${#restart_order[@]}" -eq 3 ] || fail "unable to determine deterministic Kind restart order"
printf 'Kind restart order preserving Docker IPs: %s\n' "${restart_order[*]}"

ready_nodes

# Guard against a partially recovered Docker/Kind network. After a container
# restart, Kubernetes may briefly report stale node addresses. H2 must start
# only when all three retained nodes expose distinct InternalIP values.
k get nodes -o json | py -c 'import json,sys; d=json.load(sys.stdin); ips=[next(a["address"] for a in n["status"]["addresses"] if a["type"]=="InternalIP") for n in d["items"]]; print("Kind InternalIPs: "+" ".join(ips)); assert len(ips)==3, f"expected 3 Kind InternalIPs, got {ips}"; assert len(set(ips))==3, f"duplicate/stale Kind InternalIP detected: {ips}"' \
  || fail "Kind InternalIP validation failed; wait for node network reconciliation before H2"

ensure_kyverno_webhook() {
  if ! k get namespace kyverno >/dev/null 2>&1; then
    fail "kyverno namespace missing"
  fi
  k -n kyverno rollout status deployment/kyverno-admission-controller --timeout=300s
  local deadline=$((SECONDS + 180))
  while true; do
    if k -n kyverno get endpoints kyverno-svc -o json | py -c 'import json,sys; d=json.load(sys.stdin); addrs=sum((s.get("addresses",[]) for s in d.get("subsets",[])),[]); raise SystemExit(0 if addrs else 1)' >/dev/null 2>&1; then
      echo "[PASS] Kyverno admission webhook endpoint is ready"
      return 0
    fi
    [ "$SECONDS" -lt "$deadline" ] || fail "Kyverno admission webhook endpoint did not become ready"
    sleep 3
  done
}

ensure_s3_reader() {
  local phase ready
  phase="$(k -n edl-data get pod kind-s3-reader -o jsonpath='{.status.phase}' 2>/dev/null || true)"
  ready="$(k -n edl-data get pod kind-s3-reader -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || true)"
  if [ "$phase" != "Running" ] || [ "$ready" != "true" ]; then
    echo "[INFO] recreating stateless kind-s3-reader diagnostic pod after node restart"
    ensure_kyverno_webhook
    k -n edl-data delete pod kind-s3-reader --ignore-not-found --wait=true
    k apply -f platform/kind/s3-reader.yaml
    k -n edl-data wait --for=condition=Ready pod/kind-s3-reader --timeout=300s
  fi
}

echo "===== H2 VERIFY RETAINED STATE BEFORE SWITCH ====="
ensure_s3_reader
# Polaris is intentionally in-memory. A previous node restart may already have
# emptied the catalog before the actual H2 CRC switch. Restore only the exact
# existing I12 metadata registration; never replay Kafka or rerun Spark.
py scripts/kind/restore-polaris-i12.py | tee "$H2_DIR/polaris-before-switch.txt"
py scripts/kind/test-h2.py before

{
  echo "UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "git=$(git rev-parse HEAD)"
  echo "context=$(kubectl config current-context)"
  k get nodes -o wide
  k get pvc -A
  k -n argocd get applications
} | tee "$H2_DIR/kind-before.txt"

echo "===== H2 STOP KIND WITHOUT DELETION ====="
KIND_STOPPED=true
: > "$H2_DIR/kind-stop.txt"
# Stop by stable container names, one at a time. Treat an already-stopped
# container as success and verify state explicitly after each Docker command.
for ((i=${#restart_order[@]}-1; i>=0; i--)); do
  node="${restart_order[$i]}"
  echo "[INFO] stopping $node" | tee -a "$H2_DIR/kind-stop.txt"
  state="$(docker inspect -f '{{.State.Running}}' "$node" 2>/dev/null || true)"
  if [ "$state" = "true" ]; then
    set +e
    stop_output="$(docker stop --timeout=60 "$node" 2>&1)"
    stop_rc=$?
    set -e
    printf '%s\n' "$stop_output" | tee -a "$H2_DIR/kind-stop.txt"
    state="$(docker inspect -f '{{.State.Running}}' "$node" 2>/dev/null || true)"
    if [ "$state" = "true" ]; then
      fail "Docker could not stop $node (rc=$stop_rc)"
    fi
    if [ "$stop_rc" -ne 0 ]; then
      echo "[WARN] docker stop returned rc=$stop_rc but $node is confirmed stopped" | tee -a "$H2_DIR/kind-stop.txt"
    fi
  else
    echo "[INFO] $node already stopped" | tee -a "$H2_DIR/kind-stop.txt"
  fi
done

for node in "${restart_order[@]}"; do
  state="$(docker inspect -f '{{.State.Running}}' "$node" 2>/dev/null || true)"
  [ "$state" != "true" ] || fail "$node is still running after H2 stop phase"
done

echo '[PASS] Kind node containers stopped; containers/images/volumes preserved' | tee -a "$H2_DIR/kind-stop.txt"

echo "===== H2 START CRC ====="
umask 077
CRC_MAYBE_RUNNING=true
if ! crc start > .audit/kind/h2-crc-start-private.log 2>&1; then
  fail "crc start failed; private output retained under .audit/kind"
fi

kubectl config use-context crc-admin >/dev/null
kubectl --context=crc-admin wait --for=condition=Ready nodes --all --timeout=600s

{
  echo "UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "H2_CRC_INSPECTION=READ_ONLY"
  crc status
  kubectl --context=crc-admin get nodes -o wide
  kubectl --context=crc-admin get projects
  kubectl --context=crc-admin get pods -A
  echo '[PASS] CRC started and was inspected read-only; no workload mutation command executed by H2'
} | tee "$H2_DIR/crc-readonly.txt"

echo "===== H2 STOP CRC ====="
crc stop | tee "$H2_DIR/crc-stop.txt"
CRC_MAYBE_RUNNING=false

echo "===== H2 RESTART EXISTING KIND CONTAINERS ====="
{
  for node in "${restart_order[@]}"; do
    docker start "$node"
    sleep 2
  done
} | tee "$H2_DIR/kind-start.txt"

for node in "${restart_order[@]}"; do
  actual_ip="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$node")"
  [ "$actual_ip" = "${expected_docker_ip[$node]}" ] \
    || fail "Docker IP changed for $node: expected ${expected_docker_ip[$node]}, got $actual_ip"
done

kind export kubeconfig --name "$CLUSTER"
kubectl config use-context "$CONTEXT" >/dev/null
KIND_STOPPED=false

# Wait for the existing API/control plane and all three retained nodes.
deadline=$((SECONDS + 300))
until k get nodes >/dev/null 2>&1; do
  [ "$SECONDS" -lt "$deadline" ] || fail "Kind API did not return after restart"
  sleep 5
done
ready_nodes
k get nodes -o json | py -c 'import json,sys; d=json.load(sys.stdin); ips=[next(a["address"] for a in n["status"]["addresses"] if a["type"]=="InternalIP") for n in d["items"]]; print("Kind InternalIPs after restart: "+" ".join(ips)); assert len(ips)==3, f"expected 3 Kind InternalIPs after restart, got {ips}"; assert len(set(ips))==3, f"duplicate/stale Kind InternalIP detected after restart: {ips}"' \
  || fail "Kind InternalIP validation failed after restart"

echo "===== H2 WAIT RETAINED WORKLOADS ====="
for namespace in argocd edl-platform edl-data edl-observability kyverno; do
  if k get namespace "$namespace" >/dev/null 2>&1; then
    while IFS= read -r deployment; do
      [ -n "$deployment" ] || continue
      k -n "$namespace" rollout status "$deployment" --timeout=600s
    done < <(k -n "$namespace" get deployments -o name)
  fi
done
k -n edl-data wait --for=condition=Ready kafka/edl-kafka --timeout=600s
ensure_s3_reader

echo "===== H2 POLARIS RETENTION / METADATA-ONLY RECOVERY ====="
# Polaris is intentionally in-memory in this lab. If its catalog disappeared,
# re-register the exact existing I12 metadata file; never replay Kafka/Spark.
py scripts/kind/restore-polaris-i12.py | tee "$H2_DIR/polaris-after-restart.txt"

# Trino/Jupyter may have become Ready before the catalog registration; no rollout
# is required because both resolve the REST catalog dynamically.
echo "===== H2 FINAL READ-ONLY VALIDATION ====="
py scripts/kind/test-h2.py after

{
  echo "UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "context=$(kubectl config current-context)"
  k get nodes -o wide
  k get pvc -A
  k -n argocd get applications
  k -n edl-data get kafka edl-kafka
  k -n edl-data get deployment edl-s3 edl-polaris edl-trino-coordinator edl-trino-worker edl-jupyter
} | tee "$H2_DIR/kind-after.txt"

cat > "$H2_DIR/README.md" <<EOF
# H2 — Kind -> CRC -> Kind local switch

Result: **KIND_CRC_KIND_LOCAL_SWITCH_VALIDATED**

- Start state: retained `kind-edl-lab`, 3 Ready nodes.
- H1 prerequisite: locally validated and pushed before H2.
- Kind stop/start used the existing three Docker node containers; no Kind delete/recreate.
- CRC was started and inspected read-only; H2 issued no CRC workload mutation.
- CRC was stopped before the existing Kind containers were restarted.
- Final Kind state passed the repository health gate.
- Exactly six retained Iceberg transactions were verified.
- Retained I12 event: `$I12_EVENT`.
- Jupyter persistent marker and Jupyter -> Trino -> I12 passed after the switch.
- S3 metadata retained the exact I12 snapshot/table UUID.
- Polaris is an in-memory lab catalog. If it was empty after process restart, H2 used metadata-only registration of the already-existing I12 Iceberg metadata file. It did not replay Kafka, rerun the batch transform, or rewrite S3/Iceberg data.
- No namespace, PVC, cluster or retained application data was deleted.

This validates local operational switching on one workstation. It is not multi-host HA, DR, durable-catalog or production approval.
EOF

echo "===== H2 PUBLISHABLE EVIDENCE SECRET GUARD ====="
if grep -R -nE 'github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|(AKIA|ASIA)[A-Z0-9]{16}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|sha256~[A-Za-z0-9_-]{30,}' "$H2_DIR"; then
  fail "secret-like material detected in H2 evidence; nothing will be committed"
fi

echo "===== H2 COMMIT / PUSH ====="
git add "$H2_DIR"
BAD="$(git diff --cached --name-only | grep -v "^$H2_DIR/" || true)"
[ -z "$BAD" ] || fail "unexpected staged path(s): $BAD"
git diff --cached --check

if git diff --cached --quiet; then
  echo '[INFO] no new H2 evidence to commit'
else
  git commit -m "test(runtime): validate Kind CRC Kind local switch"
  git push origin "$BRANCH"
fi

SUCCESS=true
trap - EXIT

echo "===== H2 PASS ====="
echo "KIND_CRC_KIND_LOCAL_SWITCH_VALIDATED"
echo "head=$(git rev-parse HEAD)"
echo "context=$(kubectl config current-context)"
echo "I12_EVENT=$I12_EVENT"
git status --short
