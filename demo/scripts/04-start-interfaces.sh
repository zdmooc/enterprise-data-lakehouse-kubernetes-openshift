#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

[ "$(kubectl config current-context)" = "kind-edl-lab" ] || { echo "[FAIL] expected kind-edl-lab"; exit 1; }

DIR=".audit/demo-port-forwards"
mkdir -p "$DIR"

start_pf() {
  local name="$1" ns="$2" svc="$3" local_port="$4" remote_port="$5"
  local pidfile="$DIR/$name.pid" logfile="$DIR/$name.log"

  if [ -f "$pidfile" ]; then
    oldpid="$(cat "$pidfile")"
    if kill -0 "$oldpid" 2>/dev/null; then
      echo "[INFO] $name already running pid=$oldpid"
      return 0
    fi
    rm -f "$pidfile"
  fi

  nohup kubectl --context=kind-edl-lab -n "$ns" port-forward     "svc/$svc" "$local_port:$remote_port" --address=127.0.0.1     >"$logfile" 2>&1 &
  pid=$!
  echo "$pid" > "$pidfile"
  sleep 2

  if ! kill -0 "$pid" 2>/dev/null; then
    echo "[FAIL] $name port-forward exited; see $logfile"
    cat "$logfile"
    exit 1
  fi
  echo "[PASS] $name pid=$pid"
}

start_pf argocd     argocd            argocd-server             18081 443
start_pf grafana    edl-observability edl-monitoring-grafana    13000 80
start_pf prometheus edl-observability edl-monitoring-prometheus 19090 9090
start_pf jupyter    edl-data          edl-jupyter                18888 8888
start_pf trino      edl-data          edl-trino                  18080 8080
start_pf polaris    edl-data          edl-polaris                18181 8181
start_pf s3         edl-data          edl-s3                     19000 9000

echo
echo "Argo CD    : https://127.0.0.1:18081"
echo "Grafana    : http://127.0.0.1:13000"
echo "Prometheus : http://127.0.0.1:19090"
echo "Jupyter    : http://127.0.0.1:18888"
echo "Trino      : http://127.0.0.1:18080"
echo "Polaris API: http://127.0.0.1:18181"
echo "S3 health  : http://127.0.0.1:19000/health"
echo
echo "Credentials are intentionally not printed."
echo "[PASS] demo interfaces started"
