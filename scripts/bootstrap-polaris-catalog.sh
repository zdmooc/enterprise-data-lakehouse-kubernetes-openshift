#!/usr/bin/env bash
set -euo pipefail

command -v oc >/dev/null 2>&1 || { echo "[FAIL] oc required"; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "[FAIL] curl required"; exit 1; }
command -v python >/dev/null 2>&1 || { echo "[FAIL] python required"; exit 1; }

required=(S3_ENDPOINT S3_BUCKET)
for v in "${required[@]}"; do
  [ -n "${!v:-}" ] || { echo "[FAIL] missing environment variable: $v"; exit 1; }
done

NS=edl-data
S3_REGION="${S3_REGION:-us-east-1}"
S3_ENDPOINT_INTERNAL="${S3_ENDPOINT_INTERNAL:-$S3_ENDPOINT}"
LOCAL_PORT="${POLARIS_LOCAL_PORT:-18181}"

client_id="$(oc -n "$NS" get secret polaris-client -o jsonpath='{.data.CLIENT_ID}' | base64 --decode)"
client_secret="$(oc -n "$NS" get secret polaris-client -o jsonpath='{.data.CLIENT_SECRET}' | base64 --decode)"

oc -n "$NS" port-forward svc/edl-polaris "$LOCAL_PORT:8181" >/tmp/edl-polaris-portforward.log 2>&1 &
pf_pid=$!
trap 'kill "$pf_pid" >/dev/null 2>&1 || true' EXIT
sleep 3

token_json="$(curl --fail-with-body -s   "http://127.0.0.1:$LOCAL_PORT/api/catalog/v1/oauth/tokens"   --user "$client_id:$client_secret"   -H 'Polaris-Realm: POLARIS'   -d grant_type=client_credentials   -d scope=PRINCIPAL_ROLE:ALL)"

token="$(TOKEN_JSON="$token_json" python - <<'PY'
import json, os
print(json.loads(os.environ["TOKEN_JSON"])["access_token"])
PY
)"

payload="$(S3_ENDPOINT="$S3_ENDPOINT"   S3_ENDPOINT_INTERNAL="$S3_ENDPOINT_INTERNAL"   S3_BUCKET="$S3_BUCKET"   S3_REGION="$S3_REGION"   python - <<'PY'
import json, os
bucket=os.environ["S3_BUCKET"]
payload={
  "catalog":{
    "name":"quickstart_catalog",
    "type":"INTERNAL",
    "readOnly":False,
    "properties":{"default-base-location":f"s3://{bucket}"},
    "storageConfigInfo":{
      "storageType":"S3",
      "endpoint":os.environ["S3_ENDPOINT"],
      "endpointInternal":os.environ["S3_ENDPOINT_INTERNAL"],
      "pathStyleAccess":True,
      "region":os.environ["S3_REGION"],
    },
  }
}
print(json.dumps(payload))
PY
)"

status="$(curl -s -o /tmp/edl-polaris-catalog.out -w '%{http_code}'   -H "Authorization: Bearer $token"   -H 'Polaris-Realm: POLARIS'   -H 'Content-Type: application/json'   -X POST   "http://127.0.0.1:$LOCAL_PORT/api/management/v1/catalogs"   -d "$payload")"

if [ "$status" != "200" ] && [ "$status" != "201" ] && [ "$status" != "409" ]; then
  cat /tmp/edl-polaris-catalog.out
  echo "[FAIL] Polaris catalog creation returned HTTP $status"
  exit 1
fi

grant_status="$(curl -s -o /tmp/edl-polaris-grant.out -w '%{http_code}'   -H "Authorization: Bearer $token"   -H 'Polaris-Realm: POLARIS'   -H 'Content-Type: application/json'   -X PUT   "http://127.0.0.1:$LOCAL_PORT/api/management/v1/catalogs/quickstart_catalog/catalog-roles/catalog_admin/grants"   -d '{"type":"catalog","privilege":"CATALOG_MANAGE_CONTENT"}')"

if [ "$grant_status" != "200" ] && [ "$grant_status" != "201" ] && [ "$grant_status" != "204" ] && [ "$grant_status" != "409" ]; then
  cat /tmp/edl-polaris-grant.out
  echo "[FAIL] Polaris grant returned HTTP $grant_status"
  exit 1
fi

echo "[PASS] Polaris catalog quickstart_catalog is available for s3://$S3_BUCKET"
