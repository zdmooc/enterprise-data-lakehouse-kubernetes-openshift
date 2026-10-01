#!/usr/bin/env bash
# Revalidate the existing I8 deployment without rebuilding or deploying other gates.
source "$(dirname "$0")/common.sh"
guard
{
  date -u +'%Y-%m-%dT%H:%M:%SZ'
  kubectl config current-context
  k get nodes
  k -n edl-data rollout status deployment/edl-jupyter --timeout=180s
  k -n edl-data wait --for=condition=Ready pod -l app=edl-jupyter --timeout=180s
  k -n edl-data wait --for=jsonpath='{.status.phase}'=Bound pvc/jupyter-workspace --timeout=60s
  k -n edl-data get pods -l app=edl-jupyter -o wide
  k -n edl-data get pvc jupyter-workspace
  k -n edl-data get service edl-jupyter
  k -n edl-data get pods -l app=edl-jupyter -o jsonpath='{range .items[*]}{.status.containerStatuses[0].imageID}{"\n"}{end}'
  k -n edl-data exec deployment/edl-jupyter -- python -c 'import os,urllib.request; r=urllib.request.Request("http://127.0.0.1:8888/api/status",headers={"Authorization":"token "+os.environ["JUPYTER_TOKEN"].strip()}); status=urllib.request.urlopen(r,timeout=15).status; assert status==200; print("JUPYTER_HTTP_STATUS="+str(status))'
  k -n edl-data exec deployment/edl-jupyter -- python /opt/edl-samples/trino_lakehouse_query.py
  k -n edl-data exec deployment/edl-jupyter -- python -c 'import os,trino; c=trino.dbapi.connect(host=os.environ["TRINO_HOST"],port=int(os.environ.get("TRINO_PORT","8080")),user="data-analyst",catalog="polaris",schema="analytics"); cur=c.cursor(); cur.execute("SELECT eventId, transactionId, amount, status FROM transactions ORDER BY eventId"); rows=cur.fetchall(); assert {"evt-0001","evt-0002","evt-0003","evt-0004","evt-0005"} <= {r[0] for r in rows}; print("EDL_JUPYTER_ICEBERG_TRANSACTIONS="+str(len(rows))); [print(r) for r in rows]'
  k -n edl-data exec deployment/edl-jupyter -- python -c 'from pathlib import Path; p=Path("/home/jovyan/work/kind-volume-proof.txt"); assert p.read_text()=="kind-jupyter-persistence"; print("[PASS] Jupyter PVC proof retained")'
  echo '[PASS] I8 Jupyter: Ready pod, Bound PVC, authenticated HTTP, Trino connection and real Iceberg transactions'
} | tee "$EVIDENCE_DIR/15-jupyter.txt"
