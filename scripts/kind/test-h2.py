"""Read-only H2 checks before/after Kind -> CRC -> Kind switching."""
import importlib.util
import json
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location('i12', Path(__file__).with_name('test-e2e.py'))
e = importlib.util.module_from_spec(spec)
spec.loader.exec_module(e)
e.guard()

mode = sys.argv[1] if len(sys.argv) > 1 else 'after'
if mode not in ('before', 'after'):
    raise SystemExit('Expected before or after')

i12 = Path(e.BASE) / 'i12'
out = Path(e.BASE) / 'h2-kind-crc-kind'
out.mkdir(exist_ok=True)
e.OUT = out
payload = json.loads((i12 / 'transaction.json').read_text(encoding='utf-8'))
expected_catalog = json.loads((i12 / 'polaris-after.json').read_text(encoding='utf-8'))
event = payload['eventId']

with e.evidence(mode + '-state'):
    catalog = e.polaris()
    assert catalog == expected_catalog, 'Polaris catalog/snapshot differs from I12'

    rows = e.sql('SELECT eventId AS "eventId" FROM polaris.analytics.transactions ORDER BY eventId')
    expected_ids = {event, *(f'evt-{i:04d}' for i in range(1, 6))}
    assert len(rows) == 6
    assert {r['eventId'] for r in rows} == expected_ids
    e.emit('H2_ICEBERG_TOTAL=6')
    e.emit('H2_I12_EVENT=' + event)

    target = e.sql(
        'SELECT eventId AS "eventId", amount FROM polaris.analytics.transactions '
        f"WHERE eventId='{event}'"
    )
    assert len(target) == 1 and target[0]['eventId'] == event and target[0]['amount'] == payload['amount']

    metadata_key = expected_catalog['metadata-location'].removeprefix('s3://edl-lab/')
    raw = e.k(
        '-n', 'edl-data', 'exec', 'kind-s3-reader', '--', 'bash', '-ec',
        'aws --endpoint-url "$S3_ENDPOINT" s3 cp "s3://$S3_BUCKET/' + metadata_key + '" - --only-show-errors',
        show=False,
    )
    metadata = json.loads(raw)
    assert metadata['current-snapshot-id'] == expected_catalog['snapshot-id']
    assert metadata['table-uuid'] == expected_catalog['table-uuid']
    e.emit('H2_S3_METADATA_SNAPSHOT=' + str(metadata['current-snapshot-id']))
    e.emit('H2_S3_TABLE_UUID=' + metadata['table-uuid'])

    e.run([sys.executable, 'scripts/kind/check-health.py'])

if mode == 'after':
    with e.evidence('jupyter-after-switch'):
        code = '''import os,trino
from pathlib import Path
assert Path("/home/jovyan/work/kind-volume-proof.txt").read_text()=="kind-jupyter-persistence"
c=trino.dbapi.connect(host=os.environ["TRINO_HOST"],port=8080,user="data-analyst",catalog="polaris",schema="analytics")
q=c.cursor(); q.execute("SELECT eventId FROM transactions WHERE eventId = ?", ["E2E-I12-20260930T051236Z-a0adb24c8c95"])
rows=q.fetchall(); assert rows==[["E2E-I12-20260930T051236Z-a0adb24c8c95"]]
print("H2_JUPYTER_TRINO_I12=PASS")
print("H2_JUPYTER_PERSISTENT_MARKER=PASS")
'''
        e.k('-n', 'edl-data', 'exec', 'deployment/edl-jupyter', '--', 'python', '-c', code, timeout=180)
    e.finish()
    print('KIND_CRC_KIND_LOCAL_SWITCH_VALIDATED')
