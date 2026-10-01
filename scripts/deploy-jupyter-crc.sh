#!/usr/bin/env bash
set -euo pipefail
bash scripts/apply-data-networking.sh

command -v oc >/dev/null 2>&1 || {
  echo "[FAIL] oc is required"
  exit 1
}

oc get ns edl-data >/dev/null 2>&1 || {
  echo "[FAIL] edl-data namespace missing; apply I2 baseline first"
  exit 1
}

existing="$(oc -n edl-data get secret jupyter-auth --ignore-not-found -o jsonpath='{.data.token}')"
if [ -n "$existing" ]; then
  token="$(printf '%s' "$existing" | base64 --decode)"
elif command -v openssl >/dev/null 2>&1; then
  token="$(openssl rand -hex 24)"
else
  token="$(python - <<'PY'
import secrets
print(secrets.token_hex(24))
PY
)"
fi

oc -n edl-data create secret generic jupyter-auth   --from-literal=token="$token"   --dry-run=client -o yaml | oc apply -f -

oc apply -f data-platform/jupyter/openshift/buildconfig.yaml

echo "[INFO] starting Jupyter image build"
oc -n edl-data start-build edl-jupyter --follow --wait

oc apply -k data-platform/jupyter/openshift

echo "[INFO] waiting for Jupyter"
oc -n edl-data rollout status deployment/edl-jupyter --timeout=600s

pod="$(oc -n edl-data get pod -l app=edl-jupyter -o jsonpath='{.items[0].metadata.name}')"

echo "[INFO] validating workspace write"
oc -n edl-data exec "$pod" -- sh -c 'id && echo workspace-ok > /home/jovyan/work/.write-test && cat /home/jovyan/work/.write-test'

route="$(oc -n edl-data get route edl-jupyter -o jsonpath='{.spec.host}')"

echo "[PASS] JupyterLab deployed"
echo "URL: https://$route"
echo "[INFO] Retrieve the token privately from Secret jupyter-auth; do not include it in evidence logs."
