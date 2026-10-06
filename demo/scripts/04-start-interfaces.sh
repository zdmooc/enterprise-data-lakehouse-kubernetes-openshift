#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    SCRIPT_WIN="$(cygpath -w "$ROOT/demo/scripts/04-start-interfaces-windows.ps1")"
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_WIN"
    exit $?
    ;;
esac

[ "$(kubectl config current-context)" = "kind-edl-lab" ] || { echo "[FAIL] expected kind-edl-lab"; exit 1; }

DIR=.audit/demo-port-forwards
mkdir -p "$DIR"

start_pf() {
  local name="$1" ns="$2" svc="$3" local_port="$4" remote_port="$5"
  local pidfile="$DIR/$name.pid" logfile="$DIR/$name.log"
  if [ -f "$pidfile" ]; then
    oldpid="$(cat "$pidfile")"
    if kill -0 "$oldpid" 2>/dev/null; then echo "[INFO] $name already running pid=$oldpid"; return 0; fi
    rm -f "$pidfile"
  fi
  nohup kubectl --context=kind-edl-lab -n "$ns" port-forward "svc/$svc" "$local_port:$remote_port" --address=127.0.0.1 >"$logfile" 2>&1 &
  pid=$!
  echo "$pid" > "$pidfile"
  sleep 2
  kill -0 "$pid" 2>/dev/null || { echo "[FAIL] $name"; cat "$logfile"; exit 1; }
  echo "[PASS] $name pid=$pid"
}

start_pf argocd      argocd            argocd-server             18081 443
start_pf kafka-ui    edl-data          edl-kafka-console         18082 8080
start_pf spark-ui    edl-data          edl-spark-history         18083 18080
start_pf grafana     edl-observability edl-monitoring-grafana    13001 80
start_pf prometheus  edl-observability edl-monitoring-prometheus 19090 9090
start_pf jupyter     edl-data          edl-jupyter                18888 8888
start_pf trino       edl-data          edl-trino                  18080 8080
start_pf polaris-api edl-data          edl-polaris                18181 8181
start_pf polaris-ui  edl-data          edl-polaris-console        18182 8080
start_pf s3-api      edl-data          edl-s3                     19000 9000
start_pf s3-ui       edl-data          edl-s3                     19001 9001

echo
echo '===== VISUAL DEMO URLS ====='
echo 'Argo CD              https://127.0.0.1:18081'
echo 'Kafka / Redpanda UI  http://127.0.0.1:18082'
echo 'Spark History Server http://127.0.0.1:18083'
echo 'Grafana              http://127.0.0.1:13001'
echo 'Prometheus           http://127.0.0.1:19090'
echo 'Jupyter              http://127.0.0.1:18888'
echo 'Trino                 http://127.0.0.1:18080'
echo 'Polaris Console       http://127.0.0.1:18182'
echo 'Polaris API           http://127.0.0.1:18181'
echo 'RustFS Console        http://127.0.0.1:19001'
echo 'RustFS/S3 API         http://127.0.0.1:19000'
