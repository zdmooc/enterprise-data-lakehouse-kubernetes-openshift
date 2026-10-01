#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
docker build -t edl-jupyter:kind-2026-07-28 data-platform/jupyter/image
kind load docker-image edl-jupyter:kind-2026-07-28 --name "$CLUSTER"
if ! k -n edl-data get secret jupyter-auth >/dev/null 2>&1; then
  umask 077
  printf '%s' "$(openssl rand -hex 24)" > .audit/kind/jupyter-token
  k -n edl-data create secret generic jupyter-auth --from-file=token=.audit/kind/jupyter-token
  rm -f .audit/kind/jupyter-token
fi
guard
k apply -k data-platform/jupyter/profiles/kind
k -n edl-data rollout status deployment/edl-jupyter --timeout=600s
{
  k -n edl-data exec deployment/edl-jupyter -- python -c 'import os,urllib.request; r=urllib.request.Request("http://127.0.0.1:8888/api/status",headers={"Authorization":"token "+os.environ["JUPYTER_TOKEN"].strip()}); print("JUPYTER_HTTP_STATUS="+str(urllib.request.urlopen(r).status))'
  k -n edl-data exec deployment/edl-jupyter -- python /opt/edl-samples/trino_lakehouse_query.py
  k -n edl-data exec deployment/edl-jupyter -- python -c 'from pathlib import Path; p=Path("/home/jovyan/work/kind-volume-proof.txt"); p.write_text("kind-jupyter-persistence"); assert p.read_text()=="kind-jupyter-persistence"; print("[PASS] Jupyter workspace PVC is writable")'
} | tee "$EVIDENCE_DIR/15-jupyter.txt"
resource_check | tee -a "$EVIDENCE_DIR/20-resource-usage.txt"
