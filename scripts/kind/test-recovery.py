"""I11 only: ordered functional recovery on one laptop, with bounded waits.

Run via recovery.sh; optionally select one named scenario to resume a failed run.
No node, namespace, PVC or cluster deletion. Evidence excludes Secret manifests.
"""
import base64
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import urllib.request
import urllib.parse
import uuid

ROOT = Path(__file__).resolve().parents[2]
os.chdir(ROOT)
EVIDENCE = Path(os.environ.get('EVIDENCE_DIR', Path('.audit/kind/evidence-dir').read_text().strip())) / 'i11'
EVIDENCE.mkdir(parents=True, exist_ok=True)
BASH = 'C:/Program Files/Git/bin/bash.exe' if os.name == 'nt' else 'bash'
os.environ.update(MSYS_NO_PATHCONV='1', MSYS2_ARG_CONV_EXCL='*')
LOG = None
REDACTIONS = set()


def emit(message):
    message = str(message)
    for value in sorted(REDACTIONS, key=len, reverse=True):
        message = message.replace(value, '[REDACTED]')
    print(message, flush=True)
    if LOG:
        LOG.write(message + '\n')
        LOG.flush()


def run(args, data=None, show=True, check=True, timeout=120):
    # Byte stdin preserves LF for scripts sent from Windows to Linux containers.
    result = subprocess.run(args, input=data.encode('utf-8') if data is not None else None,
                            capture_output=True, timeout=timeout)
    result.stdout = result.stdout.decode('utf-8', errors='replace').replace('\r\n', '\n')
    result.stderr = result.stderr.decode('utf-8', errors='replace').replace('\r\n', '\n')
    if show:
        emit(result.stdout.rstrip())
        if result.stderr.strip():
            emit(result.stderr.rstrip())
    if check and result.returncode:
        raise RuntimeError(f'Command failed ({result.returncode}): {args[0:4]}')
    return result


def guard():
    assert run(['kubectl', 'config', 'current-context'], show=False).stdout.strip() == 'kind-edl-lab'


def k(*args, **kwargs):
    guard()
    return run(['kubectl', '--context=kind-edl-lab', *args], **kwargs)


def obj(*args):
    return json.loads(k(*args, '-o', 'json', show=False).stdout)


def wait(predicate, timeout=600):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        value = predicate()
        if value:
            return value
        time.sleep(3)
    raise RuntimeError(f'WAIT exceeded {timeout}s')


def ready(pod):
    return not pod['metadata'].get('deletionTimestamp') and pod['status'].get('phase') == 'Running' and any(
        c['type'] == 'Ready' and c['status'] == 'True' for c in pod['status'].get('conditions', []))


def pods(selector):
    return obj('-n', 'edl-data', 'get', 'pods', '-l', selector)['items']


def pod_record(pod):
    return {'name': pod['metadata']['name'], 'uid': pod['metadata']['uid'],
            'node': pod['spec'].get('nodeName'), 'ready': ready(pod),
            'restarts': sum(c['restartCount'] for c in pod['status'].get('containerStatuses', []))}


def replace(selector, observer=None):
    before = pods(selector)
    assert len(before) == 1 and ready(before[0]), 'Expected one Ready target pod'
    old = before[0]
    assert old['metadata'].get('ownerReferences'), 'Refusing deletion of an unmanaged pod'
    emit('BEFORE ' + json.dumps(pod_record(old)))
    emit('ACTION delete only pod/' + old['metadata']['name'])
    started = time.monotonic()
    k('-n', 'edl-data', 'delete', 'pod', old['metadata']['name'], '--wait=false')
    emit('WAIT for different UID and Ready')

    def replacement():
        if observer:
            observer()
        candidates = pods(selector)
        new = [p for p in candidates if p['metadata']['uid'] != old['metadata']['uid'] and ready(p)]
        return new[0] if len(new) == 1 and len(candidates) == 1 else None

    new = wait(replacement)
    emit('AFTER ' + json.dumps(pod_record(new)))
    emit(f'REPLACEMENT_READY_SECONDS={time.monotonic() - started:.1f}')
    return old, new


def pvc(name):
    item = obj('-n', 'edl-data', 'get', 'pvc', name)
    assert item['status']['phase'] == 'Bound'
    record = {'name': name, 'uid': item['metadata']['uid'], 'volume': item['spec']['volumeName'], 'phase': 'Bound'}
    emit(json.dumps(record))
    return record


QUERY = '''import os,trino
c=trino.dbapi.connect(host=os.environ['TRINO_HOST'],port=8080,user='data-analyst',catalog='polaris',schema='analytics')
cur=c.cursor(); cur.execute('SELECT 1'); assert cur.fetchall()==[[1]]; print('SELECT_1=PASS')
cur.execute('SELECT eventId,transactionId,amount,status FROM transactions ORDER BY eventId'); rows=cur.fetchall()
assert len(rows)==5 and {r[0] for r in rows}=={f'evt-{i:04d}' for i in range(1,6)}, rows
print('ICEBERG_TRANSACTIONS=5'); [print(r) for r in rows]
'''


def query():
    k('-n', 'edl-data', 'exec', 'deployment/edl-jupyter', '--', 'python', '-c', QUERY)


def marker():
    k('-n', 'edl-data', 'exec', 'deployment/edl-jupyter', '--', 'python', '-c',
      'from pathlib import Path; assert Path("/home/jovyan/work/kind-volume-proof.txt").read_text()=="kind-jupyter-persistence"; print("PERSISTENT_MARKER=PASS")')


def jupyter():
    emit('BEFORE PVC / persistent marker / functional query')
    before = pvc('jupyter-workspace')
    marker()
    query()
    replace('app=edl-jupyter')
    assert pvc('jupyter-workspace') == before
    marker()
    query()


def trino():
    selector = 'app.kubernetes.io/component=coordinator,app.kubernetes.io/name=trino'
    coordinator = pod_record(pods(selector)[0])
    assert coordinator['ready']
    emit('BEFORE coordinator ' + json.dumps(coordinator))
    query()
    observations = []
    def check_coordinator():
        record = pod_record(pods(selector)[0])
        assert record == coordinator, 'Coordinator became unready or changed during recovery'
        observations.append(record)
    replace('app.kubernetes.io/component=worker,app.kubernetes.io/name=trino', check_coordinator)
    emit(f'COORDINATOR_HEALTHY_SAMPLES_DURING_WAIT={len(observations)}')
    after = pod_record(pods(selector)[0])
    emit('AFTER coordinator ' + json.dumps(after))
    assert after == coordinator, 'Coordinator changed during worker replacement'
    query()


def kafka_cli(tool, *args, data=None):
    return k('-n', 'edl-data', 'exec', '-i', 'kind-kafka-client', '--',
             '/opt/kafka/bin/kafka-' + tool + '.sh', '--bootstrap-server',
             'edl-kafka-kafka-bootstrap:9092', *args, data=data).stdout.strip()


def kafka():
    pool = obj('-n', 'edl-data', 'get', 'kafkanodepool', 'dual-role')
    assert pool['spec']['replicas'] == 1 and set(pool['spec']['roles']) == {'broker', 'controller'}
    broker = pods('strimzi.io/name=edl-kafka-kafka')
    assert len(broker) == 1 and broker[0]['metadata']['name'] == 'edl-kafka-dual-role-0'
    before = pvc('data-0-edl-kafka-dual-role-0')
    kafka_cli('topics', '--describe', '--topic', 'edl.smoke')
    replace('strimzi.io/name=edl-kafka-kafka')
    k('-n', 'edl-data', 'wait', '--for=condition=Ready', 'kafka/edl-kafka', '--timeout=180s', timeout=190)
    assert pvc('data-0-edl-kafka-dual-role-0') == before
    kafka_cli('metadata-quorum', 'describe', '--status')
    kafka_cli('topics', '--describe', '--topic', 'edl.smoke')
    offset = kafka_cli('get-offsets', '--topic', 'edl.smoke', '--time', '-1').split(':')[-1]
    assert offset.isdigit()
    event = 'i11-recovery-' + uuid.uuid4().hex
    kafka_cli('console-producer', '--topic', 'edl.smoke', data=event + '\n')
    received = kafka_cli('console-consumer', '--topic', 'edl.smoke', '--partition', '0',
                         '--offset', offset, '--max-messages', '1', '--timeout-ms', '30000')
    assert received == event
    emit(f'FRESH_EVENT_PRODUCED_AND_CONSUMED={event}; OFFSET={offset}')


def catalogs():
    secret = obj('-n', 'edl-data', 'get', 'secret', 'polaris-client')['data']
    client = {key: base64.b64decode(value).decode() for key, value in secret.items()}
    REDACTIONS.update(value for value in client.values() if len(value) > 8)
    pf = subprocess.Popen(['kubectl', '--context=kind-edl-lab', '-n', 'edl-data', 'port-forward',
                           'svc/edl-polaris', '18182:8181', '--address=127.0.0.1'],
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        basic = base64.b64encode((client['CLIENT_ID'] + ':' + client['CLIENT_SECRET']).encode()).decode()
        REDACTIONS.add(basic)
        request = urllib.request.Request('http://127.0.0.1:18182/api/catalog/v1/oauth/tokens',
            data=urllib.parse.urlencode({'grant_type': 'client_credentials', 'scope': 'PRINCIPAL_ROLE:ALL'}).encode(),
            headers={'Authorization': 'Basic ' + basic, 'Polaris-Realm': 'POLARIS'})
        def authenticate():
            if pf.poll() is not None:
                raise RuntimeError('Polaris port-forward exited')
            try:
                with urllib.request.urlopen(request, timeout=5) as response:
                    return json.load(response)['access_token']
            except OSError:
                return None
        token = wait(authenticate, 90)
        REDACTIONS.add(token)
        request = urllib.request.Request('http://127.0.0.1:18182/api/management/v1/catalogs',
            headers={'Authorization': 'Bearer ' + token, 'Polaris-Realm': 'POLARIS'})
        with urllib.request.urlopen(request, timeout=20) as response:
            names = [c['name'] for c in json.load(response)['catalogs']]
        emit('POLARIS_CATALOG_NAMES=' + json.dumps(names))
        return names
    finally:
        pf.terminate()
        pf.wait(timeout=15)


def polaris():
    emit('BEFORE catalog + SQL')
    assert 'quickstart_catalog' in catalogs()
    query()
    replace('app.kubernetes.io/name=polaris,app.kubernetes.io/instance=edl-polaris')
    names = catalogs()
    if 'quickstart_catalog' not in names:
        emit('OBSERVED_EXPECTED_LIMIT: in-memory catalog LOST after pod replacement')
        result = k('-n', 'edl-data', 'exec', 'deployment/edl-jupyter', '--', 'python', '-c', QUERY, check=False)
        emit(f'POST_RESTART_SQL_EXIT={result.returncode}; cached SQL success would not prove catalog persistence')
        polaris_resume()
    else:
        query()
        emit('Catalog retained in this run; one replacement does not establish durability')


def polaris_resume():
    emit('BEFORE resume: ' + json.dumps(catalogs()))
    emit('ACTION documented resume-data/reconstruction from retained Kafka; no new transaction production')
    os.environ['EDL_RECOVERY_EVIDENCE_DIR'] = EVIDENCE.as_posix()
    run([BASH, 'scripts/kind/resume-data.sh'], timeout=1800)
    assert 'quickstart_catalog' in catalogs()
    query()
    emit('RECOVERY=RECONSTRUCTION; POLARIS_DURABILITY=NOT_VALIDATED')


def s3exec(script):
    return k('-n', 'edl-data', 'exec', '-i', 'kind-s3-reader', '--', 'bash', '-se', data=script).stdout


def s3():
    k('apply', '-f', 'platform/kind/s3-reader.yaml')
    k('-n', 'edl-data', 'wait', '--for=condition=Ready', 'pod/kind-s3-reader', '--timeout=180s', timeout=190)
    listing = 'aws --endpoint-url "$S3_ENDPOINT" s3api list-objects-v2 --bucket "$S3_BUCKET" --output json\n'
    emit('BEFORE existing S3 objects (key/size/ETag)')
    def inventory():
        rows = json.loads(s3exec(listing)).get('Contents', [])
        assert rows and any(r['Key'].endswith('.parquet') for r in rows)
        return {r['Key']: (r['Size'], r['ETag']) for r in rows}
    before = inventory()
    volume = pvc('edl-s3')
    replace('app=edl-s3')
    assert pvc('edl-s3') == volume
    after = inventory()
    assert all(after.get(key) == value for key, value in before.items())
    emit(f'EXISTING_OBJECTS_RETAINED={len(before)}; SAME_KEYS_SIZES_ETAGS=PASS')
    s3_contract()


def s3_contract():
    emit('FUNCTIONAL_VALIDATION S3 fresh object contract after recorded replacement')
    # Execute the repository integrity contract, then explicitly verify LIST and
    # post-delete absence for an additional unique object; never delete old keys.
    s3exec(Path('scripts/s3-contract-check.sh').read_text())
    key = 'contract-tests/i11-' + uuid.uuid4().hex + '.txt'
    emit('FRESH_OBJECT_KEY=' + key)
    script = '''tmp=$(mktemp); out=$(mktemp)
trap 'rm -f "$tmp" "$out"' EXIT
printf 'i11-fresh-recovery-object\\n' > "$tmp"
aws --endpoint-url "$S3_ENDPOINT" s3api put-object --bucket "$S3_BUCKET" --key "$key" --body "$tmp"
aws --endpoint-url "$S3_ENDPOINT" s3api get-object --bucket "$S3_BUCKET" --key "$key" "$out"
cmp "$tmp" "$out"
found=$(aws --endpoint-url "$S3_ENDPOINT" s3api list-objects-v2 --bucket "$S3_BUCKET" --prefix "$key" --query 'Contents[0].Key' --output text)
[ "$found" = "$key" ]
aws --endpoint-url "$S3_ENDPOINT" s3api delete-object --bucket "$S3_BUCKET" --key "$key"
count=$(aws --endpoint-url "$S3_ENDPOINT" s3api list-objects-v2 --bucket "$S3_BUCKET" --prefix "$key" --query 'length(Contents || `[]`)' --output text)
[ "$count" = 0 ]
echo "FRESH_PUT_GET_INTEGRITY_LIST_DELETE_ABSENCE=PASS; key=$key"
'''
    s3exec('key=' + key + '\n' + script)
    query()


def argo():
    app = obj('-n', 'argocd', 'get', 'application', 'kind-edl-baseline')
    assert app['spec']['syncPolicy']['automated']['selfHeal'] is True
    assert app['status']['sync']['status'] == 'Synced' and app['status']['health']['status'] == 'Healthy'
    assert any(r['kind'] == 'ResourceQuota' and r['name'] == 'edl-data-quota' for r in app['status']['resources'])
    quota = obj('-n', 'edl-data', 'get', 'resourcequota', 'edl-data-quota')
    expected = quota['spec']['hard']['requests.cpu']
    assert expected == '6', 'Expected current Git quota'
    emit(f'BEFORE kind-edl-baseline Synced/Healthy; requests.cpu={expected}')
    patch = {'spec': {'hard': {'requests.cpu': '7'}}}
    emit('ACTION non-destructive drift: relax requests.cpu quota from 6 to 7')
    changed = json.loads(k('-n', 'edl-data', 'patch', 'resourcequota', 'edl-data-quota',
        '--type=merge', '-p', json.dumps(patch), '-o', 'json', show=False).stdout)
    assert changed['spec']['hard']['requests.cpu'] == '7'
    emit('DRIFT_CONFIRMED=7; WAIT for automatic self-heal (no manual sync/apply)')
    start = time.monotonic()
    def healed():
        current = obj('-n', 'edl-data', 'get', 'resourcequota', 'edl-data-quota')
        application = obj('-n', 'argocd', 'get', 'application', 'kind-edl-baseline')
        emit('WAIT ' + json.dumps({'quota': current['spec']['hard']['requests.cpu'],
             'sync': application['status']['sync']['status'], 'health': application['status']['health']['status']}))
        return application if (current['spec']['hard']['requests.cpu'] == expected
            and application['status']['sync']['status'] == 'Synced'
            and application['status']['health']['status'] == 'Healthy') else None
    recovered = wait(healed, 300)
    emit(f'AFTER SELF_HEAL_SECONDS={time.monotonic()-start:.1f}; requests.cpu=6; Synced/Healthy')
    emit(json.dumps(recovered['status'].get('operationState', {})))
    query()


def diagnostics():
    emit('BEFORE diagnostics: no failure injection')
    emit('ACTION existing scripts/n3-diagnostics.sh; WAIT for collection')
    # Set POSIX PATH inside Git Bash; Windows PATH conversion otherwise allows
    # the installed oc.exe to take precedence over the context-pinned adapter.
    run([BASH, '-c', 'export PATH="$PWD/scripts/kind/portable-cli:$PATH"; '
         'command -v oc; exec bash scripts/n3-diagnostics.sh'], timeout=180)
    for args in [('get', 'pods', '-A', '-o', 'wide'), ('get', 'nodes', '-o', 'wide'),
                 ('get', 'pv'), ('get', 'pvc', '-A'), ('get', 'storageclass'),
                 ('get', 'networkpolicy', '-A'), ('get', 'events', '-A', '--sort-by=.lastTimestamp'),
                 ('-n', 'argocd', 'get', 'applications')]:
        k(*args)
    k('-n', 'edl-data', 'exec', 'kind-contract', '--', 'nslookup', 'kubernetes.default.svc.cluster.local')
    assert all(any(c['type'] == 'Ready' and c['status'] == 'True' for c in n['status']['conditions'])
               for n in obj('get', 'nodes')['items'])
    assert all(p['status'].get('phase') == 'Succeeded' or ready(p) for p in obj('get', 'pods', '-A')['items'])
    assert all(p['status']['phase'] == 'Bound' for p in obj('get', 'pvc', '-A')['items'])
    for app in obj('-n', 'argocd', 'get', 'applications')['items']:
        assert app['status']['sync']['status'] == 'Synced' and app['status']['health']['status'] == 'Healthy'
    marker()
    query()
    emit('AFTER all nodes/pods/PVCs/Argo states healthy; DNS and retained SQL validated')


SCENARIOS = {'jupyter': jupyter, 'trino': trino, 'kafka': kafka, 'polaris': polaris,
             's3': s3, 'argo': argo, 'diagnostics': diagnostics}
if __name__ == '__main__':
    guard()
    selected = sys.argv[1] if len(sys.argv) > 1 else 'all'
    assert selected in (*SCENARIOS, 'all', 'polaris-resume', 's3-contract')
    for name, scenario in SCENARIOS.items():
        if selected == 'polaris-resume' and name == 'polaris':
            scenario = polaris_resume
        elif selected == 's3-contract' and name == 's3':
            scenario = s3_contract
        elif selected not in ('all', name):
            continue
        with (EVIDENCE / (name + '.txt')).open('a', encoding='utf-8') as LOG:
            emit('\nUTC=' + datetime.now(timezone.utc).isoformat() + '; SCENARIO=' + name)
            emit('CONTEXT=kind-edl-lab; RESULT_SCOPE=KIND_MULTI_NODE_FUNCTIONAL_RECOVERY')
            try:
                scenario()
                emit('[PASS] ' + name)
            except Exception as exc:
                emit('[FAIL] ' + name + ': ' + str(exc))
                raise SystemExit(1)
        LOG = None
