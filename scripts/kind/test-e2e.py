"""I12: one new synthetic transaction, real Kafka/Spark/Iceberg/SQL evidence.

Uses the acquired images and repository Spark job, with I12-only assertions added
through a ConfigMap. Never invokes inventory(), CRC, image builds or recovery tests.
"""
import base64
from contextlib import contextmanager
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid

ROOT = Path(__file__).resolve().parents[2]
os.chdir(ROOT)
BASE = Path('.audit/kind/evidence-dir').read_text().strip()
OUT = Path(BASE) / 'i12'
BASH = 'C:/Program Files/Git/bin/bash.exe' if os.name == 'nt' else 'bash'
IMAGE = 'edl-spark-lakehouse:kind-4.1.3-iceberg1.11'
LOG = None
os.environ.update(MSYS_NO_PATHCONV='1', MSYS2_ARG_CONV_EXCL='*')


class CatalogMissing(RuntimeError):
    pass


def emit(value):
    text = str(value)
    print(text, flush=True)
    if LOG:
        LOG.write(text + '\n')
        LOG.flush()


def run(args, data=None, show=True, timeout=120):
    result = subprocess.run(args, input=data.encode() if data is not None else None,
                            capture_output=True, timeout=timeout)
    stdout = result.stdout.decode('utf-8', errors='replace').replace('\r\n', '\n')
    stderr = result.stderr.decode('utf-8', errors='replace').replace('\r\n', '\n')
    if show:
        emit(stdout.rstrip())
        if stderr.strip():
            emit(stderr.rstrip())
    if result.returncode:
        raise RuntimeError(f'Command failed ({result.returncode}): {args[:4]}')
    return stdout


def guard():
    assert run(['kubectl', 'config', 'current-context'], show=False).strip() == 'kind-edl-lab', 'STOP: wrong context'


def k(*args, **kwargs):
    guard()
    return run(['kubectl', '--context=kind-edl-lab', *args], **kwargs)


def obj(*args):
    return json.loads(k(*args, '-o', 'json', show=False))


@contextmanager
def evidence(name):
    global LOG
    prior = LOG
    with (OUT / (name + '.txt')).open('a', encoding='utf-8') as current:
        LOG = current
        emit('\nUTC=' + datetime.now(timezone.utc).isoformat() + '; GATE=' + name)
        try:
            yield
            emit('[PASS] ' + name)
        except Exception as exc:
            emit('[FAIL] ' + name + ': ' + str(exc))
            raise
        finally:
            LOG = prior


def save(name, value):
    (OUT / (name + '.json')).write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8')


def load(name):
    return json.loads((OUT / (name + '.json')).read_text())


def wait(predicate, timeout=900):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        value = predicate()
        if value:
            return value
        time.sleep(4)
    raise RuntimeError('Bounded wait expired')


@contextmanager
def forward(namespace, service, port):
    with socket.socket() as sock:
        sock.bind(('127.0.0.1', 0))
        local = sock.getsockname()[1]
    process = subprocess.Popen(['kubectl', '--context=kind-edl-lab', '-n', namespace,
        'port-forward', 'svc/' + service, f'{local}:{port}', '--address=127.0.0.1'],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        def listening():
            assert process.poll() is None, 'Port-forward exited'
            try:
                with socket.create_connection(('127.0.0.1', local), timeout=1):
                    return True
            except OSError:
                return False
        wait(listening, 45)
        yield f'http://127.0.0.1:{local}'
    finally:
        process.terminate()
        process.wait(timeout=15)


def request(url, headers=None, data=None):
    req = urllib.request.Request(url, headers=headers or {}, data=data)
    with urllib.request.urlopen(req, timeout=30) as response:
        return json.load(response)


def secret(namespace, name):
    return {key: base64.b64decode(value).decode() for key, value in
            obj('-n', namespace, 'get', 'secret', name)['data'].items()}


def polaris():
    client = secret('edl-data', 'polaris-client')
    with forward('edl-data', 'edl-polaris', 8181) as url:
        basic = base64.b64encode((client['CLIENT_ID'] + ':' + client['CLIENT_SECRET']).encode()).decode()
        token = request(url + '/api/catalog/v1/oauth/tokens',
            {'Authorization': 'Basic ' + basic, 'Polaris-Realm': 'POLARIS'},
            urllib.parse.urlencode({'grant_type': 'client_credentials', 'scope': 'PRINCIPAL_ROLE:ALL'}).encode())['access_token']
        headers = {'Authorization': 'Bearer ' + token, 'Polaris-Realm': 'POLARIS'}
        try:
            raw = request(url + '/api/management/v1/catalogs/quickstart_catalog', headers)
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                raise CatalogMissing('quickstart_catalog absent') from None
            raise
        catalog = raw.get('catalog', raw)
        storage = catalog['storageConfigInfo']
        expected = {'storageType': 'S3', 'allowedLocations': ['s3://edl-lab/curated/'],
                    'endpoint': 'http://edl-s3.edl-data.svc.cluster.local:9000',
                    'endpointInternal': 'http://edl-s3.edl-data.svc.cluster.local:9000',
                    'pathStyleAccess': True, 'stsUnavailable': True, 'region': 'us-east-1'}
        assert catalog['name'] == 'quickstart_catalog'
        assert catalog['properties']['default-base-location'] == 's3://edl-lab/curated/'
        assert all(storage.get(key) == value for key, value in expected.items()), 'Storage contract mismatch'
        root = url + '/api/catalog/v1/quickstart_catalog'
        namespaces = request(root + '/namespaces', headers)['namespaces']
        tables = request(root + '/namespaces/analytics/tables', headers)['identifiers']
        assert ['analytics'] in namespaces and any(t['name'] == 'transactions' for t in tables)
        table = request(root + '/namespaces/analytics/tables/transactions', headers)
        metadata = table['metadata']
        # Allow-list only: table responses can also contain vended credentials.
        result = {'catalog': catalog['name'], 'storage': expected, 'namespace': 'analytics',
                  'table': 'transactions', 'metadata-location': table['metadata-location'],
                  'location': metadata['location'], 'snapshot-id': metadata['current-snapshot-id'],
                  'table-uuid': metadata['table-uuid']}
        assert result['location'].startswith('s3://edl-lab/curated/')
        emit(json.dumps(result, indent=2))
        return result


def health(name):
    with evidence(name):
        run([sys.executable, 'scripts/kind/check-health.py'])
        for args in [('get', 'nodes', '-o', 'wide'), ('get', 'pods', '-A'), ('get', 'pvc', '-A'),
                     ('-n', 'argocd', 'get', 'applications'), ('-n', 'edl-data', 'get', 'kafka')]:
            k(*args)
        kafka = obj('-n', 'edl-data', 'get', 'kafka', 'edl-kafka')
        assert any(c['type'] == 'Ready' and c['status'] == 'True' for c in kafka['status']['conditions'])
        for deployment in ['edl-s3', 'edl-polaris', 'edl-trino-coordinator', 'edl-trino-worker', 'edl-jupyter']:
            d = obj('-n', 'edl-data', 'get', 'deployment', deployment)
            assert d['status'].get('readyReplicas', 0) == d['spec']['replicas'] > 0, deployment
        for selector in ['app.kubernetes.io/name=grafana', 'app.kubernetes.io/name=prometheus']:
            pods = obj('-n', 'edl-observability', 'get', 'pods', '-l', selector)['items']
            assert pods and all(any(c['type'] == 'Ready' and c['status'] == 'True'
                                   for c in p['status']['conditions']) for p in pods)


def objects():
    result = k('-n', 'edl-data', 'exec', 'kind-s3-reader', '--', 'bash', '-ec',
        'aws --endpoint-url "$S3_ENDPOINT" s3api list-objects-v2 --bucket "$S3_BUCKET" --prefix curated/ --output json', show=False)
    return [{key: row[key] for key in ('Key', 'Size', 'ETag', 'LastModified')}
            for row in json.loads(result).get('Contents', [])]


def sql(query):
    emit('QUERY=' + query)
    raw = k('-n', 'edl-data', 'exec', 'deployment/edl-trino-coordinator', '--', 'trino',
        '--server', 'http://localhost:8080', '--user', 'edl', '--output-format', 'JSON', '--execute', query)
    rows = [json.loads(line) for line in raw.splitlines() if line.strip()]
    emit('ROW_COUNT=' + str(len(rows)))
    return rows


def prepare():
    with evidence('environment'):
        for command in [['git', 'status'], ['git', 'branch', '--show-current'], ['git', 'log', '--oneline', '-5'],
                        ['kubectl', 'config', 'current-context'], [BASH, '-c', 'kind get clusters']]:
            run(command)
        revision = run(['git', 'rev-parse', 'HEAD']).strip()
        if os.environ.get('EDL_EXPECTED_START_COMMIT'):
            assert revision == os.environ['EDL_EXPECTED_START_COMMIT']
        assert run(['git', 'branch', '--show-current'], show=False).strip() == 'runtime/kind-edl-lab'
        k('get', 'nodes', '-o', 'wide'); k('get', 'pods', '-A')
        expected = Path(BASE, 'spark-image.txt').read_text().strip()
        image_id = run(['docker', 'image', 'inspect', IMAGE, '--format', '{{.Id}}']).strip()
        assert image_id == expected, 'Spark image differs from acquired runtime'
        nodes = [n['metadata']['name'] for n in obj('get', 'nodes')['items']]
        for node in nodes:
            raw = run(['docker', 'exec', node, 'crictl', 'inspecti', 'docker.io/library/' + IMAGE], show=False)
            emit('CACHED_IMAGE ' + node + ' ' + json.loads(raw)['status']['id'])
    health('health-before')
    with evidence('polaris-before'):
        try:
            catalog = polaris()
        except CatalogMissing:
            emit('Catalog missing: running documented reconstruction before I12 production')
            os.environ['EDL_RECOVERY_EVIDENCE_DIR'] = OUT.as_posix()
            run([BASH, 'scripts/kind/resume-data.sh'], timeout=1800)
            catalog = polaris()
    assert not (OUT / 'transaction.json').exists(), 'Existing I12 transaction: resume another gate; do not republish'
    now = datetime.now(timezone.utc)
    event = 'E2E-I12-' + now.strftime('%Y%m%dT%H%M%SZ') + '-' + uuid.uuid4().hex[:12]
    payload = {'eventId': event, 'eventTime': now.strftime('%Y-%m-%dT%H:%M:%SZ'),
               'transactionId': event, 'amount': 17.42, 'currency': 'EUR', 'status': 'ACCEPTED',
               'channel': 'E2E', 'country': 'FR', 'latencyMs': 7}
    with evidence('trino-before'):
        assert sql(f"SELECT eventId FROM polaris.analytics.transactions WHERE eventId='{event}'") == []
    save('transaction', payload)
    before = objects()
    save('baseline', {'polaris': catalog, 'objects': before,
        'spark-image-id': obj('-n', 'edl-data', 'get', 'pod', 'kind-spark-lakehouse-driver')['status']['containerStatuses'][0]['imageID']})
    emit('NEW_EVENT_ID=' + event)


PRODUCER = '''import json,os,time
from kafka import KafkaProducer,KafkaConsumer,TopicPartition
payload=json.loads(os.environ['I12_PAYLOAD']); topic='transactions.raw'
producer=KafkaProducer(bootstrap_servers='edl-kafka-kafka-bootstrap:9092',acks='all',retries=0,value_serializer=lambda v:json.dumps(v).encode())
meta=producer.send(topic,key=payload['eventId'].encode(),value=payload).get(timeout=60)
producer.flush(); producer.close()
print('PRODUCER_ACK='+json.dumps({'eventId':payload['eventId'],'topic':meta.topic,'partition':meta.partition,'offset':meta.offset}),flush=True)
consumer=KafkaConsumer(bootstrap_servers='edl-kafka-kafka-bootstrap:9092',enable_auto_commit=False,value_deserializer=lambda v:json.loads(v.decode()))
tp=TopicPartition(topic,meta.partition); consumer.assign([tp]); consumer.seek(tp,meta.offset)
deadline=time.monotonic()+60; found=None
while time.monotonic()<deadline and found is None:
    for records in consumer.poll(timeout_ms=2000,max_records=1).values():
        for record in records:
            if record.offset==meta.offset: found=record
assert found is not None and found.value==payload
print('KAFKA_VERIFIED='+json.dumps({'topic':found.topic,'partition':found.partition,'offset':found.offset,'payload':found.value}),flush=True)
consumer.close()
'''


def producer():
    payload = load('transaction')
    name = 'kind-i12-producer-' + payload['eventId'].split('-')[-1]
    pod = {'apiVersion': 'v1', 'kind': 'Pod', 'metadata': {'name': name, 'namespace': 'edl-data',
           'labels': {'edl.network/kafka-client': 'true'}}, 'spec': {'restartPolicy': 'Never',
           'activeDeadlineSeconds': 240, 'serviceAccountName': 'data-workload', 'automountServiceAccountToken': False,
           'securityContext': {'runAsNonRoot': True, 'runAsUser': 185, 'seccompProfile': {'type': 'RuntimeDefault'}},
           'containers': [{'name': 'producer', 'image': IMAGE, 'imagePullPolicy': 'IfNotPresent',
            'command': ['python3', '-u', '-c', PRODUCER], 'env': [{'name': 'I12_PAYLOAD', 'value': json.dumps(payload)}],
            'securityContext': {'allowPrivilegeEscalation': False, 'capabilities': {'drop': ['ALL']}},
            'resources': {'requests': {'cpu': '100m', 'memory': '128Mi'}, 'limits': {'cpu': '1', 'memory': '512Mi'}}}]}}
    with evidence('producer'):
        # create, never apply: an existing producer must never be run a second time.
        k('create', '-f', '-', data=json.dumps(pod))
        k('-n', 'edl-data', 'wait', '--for=jsonpath={.status.phase}=Succeeded', 'pod/' + name, '--timeout=240s', timeout=250)
        raw = k('-n', 'edl-data', 'logs', name)
        ack = next(json.loads(line.split('=', 1)[1]) for line in raw.splitlines() if line.startswith('PRODUCER_ACK='))
        assert ack['eventId'] == payload['eventId']
    with evidence('kafka'):
        verified = next(json.loads(line.split('=', 1)[1]) for line in raw.splitlines() if line.startswith('KAFKA_VERIFIED='))
        assert verified['payload'] == payload
        assert (verified['partition'], verified['offset']) == (ack['partition'], ack['offset'])
        emit(json.dumps(verified, indent=2))
        save('kafka-record', verified)


def spark(attempt=''):
    payload = load('transaction'); suffix = payload['eventId'].split('-')[-1]
    prefix = 'kind-i12-' + suffix + attempt
    with evidence('spark'):
        source = Path('data-platform/lakehouse/jobs/transactions_to_iceberg.py').read_text()
        emit('BASE_SPARK_SCRIPT_SHA256=' + hashlib.sha256(source.encode()).hexdigest())
        extra = '\nexpected = ' + repr(payload) + '\nmatched = [r for r in rows if r.get("eventId") == expected["eventId"]]\nassert matched == [expected], matched\nprint("I12_CONSUMED_EVENT=" + json.dumps(matched[0]), flush=True)\n'
        source = source.replace('consumer.close()', 'consumer.close()\n' + extra)
        # The lab job createOrReplace replays only retained Kafka records. Preserve
        # the pre-I12 snapshot explicitly so Kafka retention cannot erase older rows.
        snapshot = load('baseline')['polaris']['snapshot-id']
        preserve = f'''history = spark.read.option("versionAsOf", "{snapshot}").table("polaris.analytics.transactions").cache()
historical_ids = {{r["eventId"] for r in history.select("eventId").collect()}}
assert expected["eventId"] not in historical_ids
print("I12_BASELINE_SNAPSHOT={snapshot}; RETAINED_EVENT_IDS=" + json.dumps(sorted(historical_ids)), flush=True)
curated = history.unionByName(curated.where(F.col("eventId") == expected["eventId"]))
'''
        source = source.replace('(\n    curated.writeTo(', preserve + '\n(\n    curated.writeTo(')
        proof = '\nmatched = spark.table("polaris.analytics.transactions").where(F.col("eventId") == expected["eventId"]).collect()\nassert len(matched) == 1 and matched[0]["amount"] == expected["amount"]\nprint("I12_ICEBERG_WRITTEN=" + json.dumps(matched[0].asDict(), default=str), flush=True)\n'
        source = source.replace('spark.stop()', proof + '\nspark.stop()')
        source = source.replace('spark.stop()', 'actual_ids = {r["eventId"] for r in spark.table("polaris.analytics.transactions").select("eventId").collect()}\nassert actual_ids == historical_ids | {expected["eventId"]}\nprint("I12_FINAL_EVENT_IDS=" + json.dumps(sorted(actual_ids)), flush=True)\nspark.stop()')
        template = Path('platform/kind/spark-template.yaml').read_text().replace('kind-spark-templates', prefix)
        submit = Path('platform/kind/spark-submit.sh').read_text().replace('kind-spark-$MODE', prefix)
        submit = submit.replace('local:///opt/spark/work-dir/jobs/transactions_to_iceberg.py', 'local:///opt/edl-templates/transactions_to_iceberg.py')
        manifest = Path('platform/kind/spark-job.yaml').read_text().replace('__MODE__', 'lakehouse').replace('kind-spark-lakehouse-submit', prefix + '-submit').replace('kind-spark-templates', prefix)
        cm = {'apiVersion': 'v1', 'kind': 'ConfigMap', 'metadata': {'name': prefix, 'namespace': 'edl-data'},
              'data': {'pod.yaml': template, 'submit.sh': submit, 'transactions_to_iceberg.py': source}}
        k('create', '-f', '-', data=json.dumps(cm))
        k('create', '-f', '-', data=manifest)
        save('spark-run', {'prefix': prefix, 'driver': prefix + '-driver'})
        def done():
            job = obj('-n', 'edl-data', 'get', 'job', prefix + '-submit')
            if job['status'].get('failed', 0):
                k('-n', 'edl-data', 'logs', 'job/' + prefix + '-submit')
                raise RuntimeError('Spark submit job failed')
            return job['status'].get('succeeded', 0) == 1
        emit('WAIT Spark submit/driver/executor completion')
        wait(done)
        driver = obj('-n', 'edl-data', 'get', 'pod', prefix + '-driver')
        logs = k('-n', 'edl-data', 'logs', prefix + '-driver', show=False)
        (OUT / ('spark-driver' + attempt + '.txt')).write_text(logs, encoding='utf-8')
        outcome = {'pod': driver['metadata']['name'], 'uid': driver['metadata']['uid'],
                   'phase': driver['status']['phase'], 'containers': driver['status']['containerStatuses']}
        save('spark-driver-status' + attempt, outcome)
        assert driver['status']['phase'] == 'Succeeded', 'Driver failed; see archived log and status'
        assert driver['status']['containerStatuses'][0]['imageID'] == load('baseline')['spark-image-id']
        selector = driver['metadata']['labels']['spark-app-selector']
        executors = obj('-n', 'edl-data', 'get', 'pods', '-l', 'spark-role=executor,spark-app-selector=' + selector)['items']
        assert executors and all(p['status']['phase'] == 'Succeeded' and
            all(s['state']['terminated']['exitCode'] == 0 for s in p['status']['containerStatuses']) for p in executors)
        for pod in [driver, *executors]:
            emit('SUCCESS ' + pod['metadata']['name'] + '; phase=' + pod['status']['phase'])
        for marker in ['I12_CONSUMED_EVENT=', 'I12_ICEBERG_WRITTEN=']:
            line = next(line for line in logs.splitlines() if line.startswith(marker))
            record = json.loads(line.split('=', 1)[1])
            assert record['eventId'] == payload['eventId'] and record['amount'] == payload['amount']
            emit(line)
        for marker in ['I12_BASELINE_SNAPSHOT=', 'I12_FINAL_EVENT_IDS=']:
            emit(next(line for line in logs.splitlines() if line.startswith(marker)))


def validate():
    payload = load('transaction'); event = payload['eventId']
    with evidence('polaris'):
        catalog = polaris()
        old = load('baseline')['polaris']
        assert catalog['snapshot-id'] != old['snapshot-id'] and catalog['metadata-location'] != old['metadata-location']
        save('polaris-after', catalog)
    with evidence('s3-iceberg'):
        after = objects(); before = {o['Key'] for o in load('baseline')['objects']}
        added = [o for o in after if o['Key'] not in before]
        assert any(o['Key'].endswith('.parquet') for o in added)
        key = catalog['metadata-location'].removeprefix('s3://edl-lab/')
        assert any(o['Key'] == key for o in added)
        emit('NEW_OBJECTS=' + json.dumps(added, indent=2))
        raw = k('-n', 'edl-data', 'exec', 'kind-s3-reader', '--', 'bash', '-ec',
            'aws --endpoint-url "$S3_ENDPOINT" s3 cp "s3://$S3_BUCKET/' + key + '" - --only-show-errors', show=False)
        meta = json.loads(raw)
        assert meta['current-snapshot-id'] == catalog['snapshot-id']
        snapshot = next(s for s in meta['snapshots'] if s['snapshot-id'] == catalog['snapshot-id'])
        emit('S3_CURRENT_SNAPSHOT=' + json.dumps({'snapshot-id': snapshot['snapshot-id'], 'summary': snapshot['summary'], 'manifest-list': snapshot['manifest-list']}))
    query = f'''SELECT eventId AS "eventId", CAST(eventTime AS VARCHAR) AS "eventTime", transactionId AS "transactionId", amount, currency, status, channel, country, latencyMs AS "latencyMs" FROM polaris.analytics.transactions WHERE eventId='{event}' '''.strip()
    with evidence('trino'):
        rows = sql(query)
        assert len(rows) == 1
        stamp = rows[0].pop('eventTime')
        assert datetime.fromisoformat(stamp.removesuffix(' UTC')).replace(tzinfo=timezone.utc) == datetime.fromisoformat(payload['eventTime'].replace('Z', '+00:00'))
        assert rows[0] == {key: value for key, value in payload.items() if key != 'eventTime'}
        emit('EVENT_ID=' + event)
        emit('PRESERVATION_CHECK: five historical events plus I12')
        retained = sql('SELECT eventId AS "eventId" FROM polaris.analytics.transactions ORDER BY eventId')
        assert len(retained) == 6 and {r['eventId'] for r in retained} == {event, *(f'evt-{i:04d}' for i in range(1, 6))}
    with evidence('jupyter'):
        emit('QUERY=' + query)
        code = '''import json,os,sys,trino
from datetime import datetime,timezone
expected=json.loads(sys.argv[1]); c=trino.dbapi.connect(host=os.environ['TRINO_HOST'],port=8080,user='data-analyst',catalog='polaris',schema='analytics')
cur=c.cursor(); cur.execute('SELECT eventId, CAST(eventTime AS VARCHAR), transactionId, amount, currency, status, channel, country, latencyMs FROM transactions WHERE eventId = ?',[expected['eventId']]); rows=cur.fetchall()
keys=['eventId','eventTime','transactionId','amount','currency','status','channel','country','latencyMs']
assert len(rows)==1
actual=dict(zip(keys,rows[0])); stamp=actual['eventTime']
assert datetime.fromisoformat(stamp.removesuffix(' UTC')).replace(tzinfo=timezone.utc)==datetime.fromisoformat(expected['eventTime'].replace('Z','+00:00'))
assert {k:v for k,v in actual.items() if k!='eventTime'}=={k:v for k,v in expected.items() if k!='eventTime'}
print('ROW_COUNT=1; EVENT_ID='+expected['eventId']); print(json.dumps(actual))
'''
        k('-n', 'edl-data', 'exec', 'deployment/edl-jupyter', '--', 'python', '-c', code, json.dumps(payload))


def finish():
    with evidence('observability'):
        with forward('edl-observability', 'edl-monitoring-prometheus', 9090) as url:
            targets = request(url + '/api/v1/targets?state=active')['data']['activeTargets']
            assert len(targets) >= 21 and all(t['health'] == 'up' for t in targets)
            pools = {t['scrapePool'] for t in targets}
            for expected in ['edl-trino-coordinator', 'edl-trino-worker', 'edl-kafka-metrics', 'edl-kafka-exporter']:
                assert any('/' + expected + '/' in pool for pool in pools)
            for t in targets:
                emit(t['scrapePool'] + ' ' + t.get('labels', {}).get('pod', '') + ' UP')
            emit('TARGETS_UP=' + str(len(targets)))
        auth = secret('edl-observability', 'kind-grafana-admin')
        headers = {'Authorization': 'Basic ' + base64.b64encode((auth['username'] + ':' + auth['password']).encode()).decode()}
        with forward('edl-observability', 'edl-monitoring-grafana', 80) as url:
            status = request(url + '/api/health', headers)
            assert status['database'] == 'ok'
            assert request(url + '/api/user', headers)['login'] == auth['username']
            emit('GRAFANA_AUTHENTICATED_API=OK; database=ok')
        emit('No claim for absent consumer-lag/PVC-capacity metrics or unexposed components; kubectl top remains NOT AVAILABLE.')
    health('health-after')


if __name__ == '__main__':
    guard()  # Stop before any evidence/file write if context differs.
    OUT.mkdir(parents=True, exist_ok=True)
    selected = sys.argv[1] if len(sys.argv) > 1 else 'all'
    gates = {'prepare': prepare, 'producer': producer, 'spark': spark, 'validate': validate, 'finish': finish}
    if selected == 'spark-retry':
        attempt = os.environ.get('EDL_I12_SPARK_ATTEMPT', 'r2')
        assert attempt.startswith('r') and attempt[1:].isdigit() and 2 <= int(attempt[1:]) <= 99
        gates = {'spark-retry': lambda: spark('-' + attempt)}
    assert selected in (*gates, 'all')
    for name, action in gates.items():
        if selected in ('all', name):
            action()
