#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

DIR=".audit/demo-port-forwards"

if [ ! -d "$DIR" ]; then
  echo "[INFO] no demo port-forward directory"
  exit 0
fi

for pidfile in "$DIR"/*.pid; do
  [ -e "$pidfile" ] || continue
  name="$(basename "$pidfile" .pid)"
  pid="$(cat "$pidfile")"
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true
    echo "[PASS] stopped $name pid=$pid"
  else
    echo "[INFO] $name pid=$pid already stopped"
  fi
  rm -f "$pidfile"
done

echo "[PASS] demo port-forwards stopped"
