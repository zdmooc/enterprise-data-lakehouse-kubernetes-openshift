"""H2 metadata-only Polaris recovery for the retained I12 Iceberg table.

If the in-memory Polaris catalog survives, this is a no-op.
If the catalog is empty after the Kind node containers restart, recreate only the
catalog/namespace registration and point it at the already-existing I12 metadata
file. Never replay Kafka and never rewrite Iceberg/S3 data.
"""
import base64
import importlib.util
import json
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

spec = importlib.util.spec_from_file_location('i12', Path(__file__).with_name('test-e2e.py'))
e = importlib.util.module_from_spec(spec)
spec.loader.exec_module(e)
e.guard()

i12 = Path(e.BASE) / 'i12'
expected = json.loads((i12 / 'polaris-after.json').read_text(encoding='utf-8'))
out = Path(e.BASE) / 'h2-kind-crc-kind'
out.mkdir(exist_ok=True)

try:
    current = e.polaris()
    if current == expected:
        print('[PASS] Polaris retained the exact I12 catalog/table; no recovery required')
        print('POLARIS_RECOVERY=NOT_REQUIRED')
        raise SystemExit(0)
    raise SystemExit('Existing Polaris table differs from the retained I12 metadata; refusing recovery')
except e.CatalogMissing:
    print('[INFO] In-memory Polaris catalog is absent after restart; metadata-only recovery is required')

# Recreate the catalog contract and grants only. This helper does not run Spark.
e.run([sys.executable, 'scripts/kind/polaris.py', 'bootstrap'])

client = e.secret('edl-data', 'polaris-client')
with e.forward('edl-data', 'edl-polaris', 8181) as root:
    basic = base64.b64encode((client['CLIENT_ID'] + ':' + client['CLIENT_SECRET']).encode()).decode()
    token = e.request(
        root + '/api/catalog/v1/oauth/tokens',
        {'Authorization': 'Basic ' + basic, 'Polaris-Realm': 'POLARIS'},
        urllib.parse.urlencode({'grant_type': 'client_credentials', 'scope': 'PRINCIPAL_ROLE:ALL'}).encode(),
    )['access_token']
    headers = {
        'Authorization': 'Bearer ' + token,
        'Polaris-Realm': 'POLARIS',
        'Content-Type': 'application/json',
    }
    api = root + '/api/catalog/v1/quickstart_catalog'

    def request(path, method='GET', payload=None, accepted=(200,)):
        req = urllib.request.Request(
            api + path,
            method=method,
            headers=headers,
            data=json.dumps(payload).encode() if payload is not None else None,
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as response:
                raw = response.read()
                if response.status not in accepted:
                    raise RuntimeError(f'{method} {path}: HTTP {response.status}')
                return json.loads(raw) if raw else None
        except urllib.error.HTTPError as exc:
            if exc.code in accepted:
                raw = exc.read()
                return json.loads(raw) if raw else None
            raise RuntimeError(f'{method} {path}: HTTP {exc.code}') from None

    # Create the namespace only if absent. 409 means it already exists.
    request('/namespaces', 'POST', {'namespace': ['analytics'], 'properties': {}}, accepted=(200, 201, 409))

    # Register the existing metadata file. This changes catalog metadata only.
    request(
        '/namespaces/analytics/register',
        'POST',
        {'name': 'transactions', 'metadata-location': expected['metadata-location']},
        accepted=(200, 409),
    )

    table = request('/namespaces/analytics/tables/transactions')
    metadata = table['metadata']
    actual = {
        'metadata-location': table['metadata-location'],
        'snapshot-id': metadata['current-snapshot-id'],
        'table-uuid': metadata['table-uuid'],
    }
    for key in actual:
        if actual[key] != expected[key]:
            raise SystemExit(f'Registered table mismatch at {key}: {actual[key]} != {expected[key]}')

verified = e.polaris()
if verified != expected:
    raise SystemExit('Metadata-only Polaris recovery did not restore the exact I12 catalog snapshot')

print('[PASS] Polaris metadata-only recovery registered the existing I12 metadata file')
print('POLARIS_RECOVERY=REGISTER_EXISTING_METADATA')
print('SNAPSHOT_ID=' + str(expected['snapshot-id']))
print('TABLE_UUID=' + expected['table-uuid'])
print('No Kafka replay; no Spark rewrite; no S3/Iceberg data rewrite')
