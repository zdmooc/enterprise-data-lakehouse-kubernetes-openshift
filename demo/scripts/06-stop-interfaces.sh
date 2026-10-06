#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    SCRIPT_WIN="$(cygpath -w "$ROOT/demo/scripts/06-stop-interfaces-windows.ps1")"
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$SCRIPT_WIN"
    exit $?
    ;;
esac

DIR=.audit/demo-port-forwards
[ -d "$DIR" ] || { echo '[INFO] no demo port-forward directory'; exit 0; }
for pidfile in "$DIR"/*.pid; do
  [ -e "$pidfile" ] || continue
  name="$(basename "$pidfile" .pid)"
  pid="$(cat "$pidfile")"
  if kill -0 "$pid" 2>/dev/null; then kill "$pid" 2>/dev/null || true; echo "[PASS] stopped $name pid=$pid"; fi
  rm -f "$pidfile"
done
echo '[PASS] demo port-forwards stopped'
