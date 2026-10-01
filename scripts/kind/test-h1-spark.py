"""H1 Spark executor smoke, Kafka read, Iceberg read/write on a disposable table.

Never invokes the producer or replaces the validated transactions table.
"""
import importlib.util
import json
from datetime import datetime, timezone
from pathlib import Path

spec = importlib.util.spec_from_file_location('i12', Path(__file__).with_name('test-e2e.py'))
e = importlib.util.module_from_spec(spec)
spec.loader.exec_module(e)
e.guard()
payload = e.load('transaction')
expected_catalog = e.load('polaris-after')
e.OUT = Path(e.BASE) / 'h1-security-hardening'
prefix = 'kind-h1-spark-' + datetime.now(timezone.utc).strftime('%H%M%S')
source = Path('data-platform/lakehouse/jobs/transactions_to_iceberg.py').read_text().split('consumer = KafkaConsumer(')[0]
source += '''
assert spark.version == '4.1.3'
assert spark.sparkContext.parallelize(range(10000), 4).map(lambda x: x*x).sum() == 333283335000
print('H1_SPARK_EXECUTOR_SMOKE=PASS', flush=True)
from kafka import TopicPartition
consumer = KafkaConsumer(bootstrap_servers=bootstrap, enable_auto_commit=False,
                         value_deserializer=lambda v: json.loads(v.decode()))
tp=TopicPartition('transactions.raw',1); consumer.assign([tp]); consumer.seek(tp,0)
records=[r for batch in consumer.poll(timeout_ms=20000).values() for r in batch]
consumer.close()
assert any(r.offset==0 and r.value==EXPECTED for r in records)
print('H1_KAFKA_EXISTING_I12=PASS; partition=1; offset=0; no publish', flush=True)
table=spark.table('polaris.analytics.transactions')
ids={r['eventId'] for r in table.select('eventId').collect()}
assert table.count()==6 and ids=={EXPECTED['eventId'],*(f'evt-{i:04d}' for i in range(1,6))}
one=table.where(F.col('eventId')==EXPECTED['eventId'])
rows=one.collect(); assert len(rows)==1 and rows[0]['amount']==EXPECTED['amount']
print('H1_ICEBERG_I12='+json.dumps(rows[0].asDict(),default=str),flush=True)
print('H1_ICEBERG_TOTAL=6',flush=True)
scratch='polaris.analytics.'+SCRATCH
assert not spark.catalog.tableExists(scratch)
one.writeTo(scratch).using('iceberg').tableProperty('format-version','2').create()
assert spark.table(scratch).count()==1
assert spark.table(scratch).first()['eventId']==EXPECTED['eventId']
spark.sql('DROP TABLE '+scratch+' PURGE')
assert not spark.catalog.tableExists(scratch)
print('H1_ICEBERG_S3_WRITE_READ_DROP=PASS; disposable='+scratch,flush=True)
spark.stop()
'''
source = 'EXPECTED='+repr(payload)+'\nSCRATCH='+repr(prefix.replace('-', '_'))+'\n'+source
template = Path('platform/kind/spark-template.yaml').read_text().replace('kind-spark-templates',prefix)
submit = Path('platform/kind/spark-submit.sh').read_text().replace('kind-spark-$MODE',prefix)
submit = submit.replace('local:///opt/spark/work-dir/jobs/transactions_to_iceberg.py','local:///opt/edl-templates/h1.py')
manifest = Path('platform/kind/spark-job.yaml').read_text().replace('__MODE__','lakehouse').replace('kind-spark-lakehouse-submit',prefix+'-submit').replace('kind-spark-templates',prefix)
cm={'apiVersion':'v1','kind':'ConfigMap','metadata':{'name':prefix,'namespace':'edl-data'},
    'data':{'pod.yaml':template,'submit.sh':submit,'h1.py':source}}
with e.evidence('spark-regression'):
    assert e.polaris()==expected_catalog
    e.k('create','-f','-',data=json.dumps(cm))
    e.k('create','-f','-',data=manifest)
    def done():
        job=e.obj('-n','edl-data','get','job',prefix+'-submit')
        assert not job['status'].get('failed',0), 'Spark submit failed'
        return job['status'].get('succeeded',0)==1
    e.wait(done)
    driver=e.obj('-n','edl-data','get','pod',prefix+'-driver')
    logs=e.k('-n','edl-data','logs',prefix+'-driver',show=False)
    # Raw logs stay ignored. Publish explicit result markers and phase/exit codes only.
    Path('.audit/kind/h1',prefix+'.log').write_text(logs,encoding='utf-8')
    selector=driver['metadata']['labels']['spark-app-selector']
    executors=e.obj('-n','edl-data','get','pods','-l','spark-role=executor,spark-app-selector='+selector)['items']
    assert executors
    for pod in [driver,*executors]:
        e.emit(json.dumps({'pod':pod['metadata']['name'],'phase':pod['status']['phase'],
                          'images':[s['imageID'] for s in pod['status']['containerStatuses']],
                          'rootReadOnly':[c.get('securityContext',{}).get('readOnlyRootFilesystem') for c in pod['spec']['containers']]}))
        assert pod['status']['phase']=='Succeeded'
        assert all(s['state']['terminated']['exitCode']==0 for s in pod['status']['containerStatuses'])
        assert all(c.get('securityContext',{}).get('readOnlyRootFilesystem') for c in pod['spec']['containers'])
    for marker in ['H1_SPARK_EXECUTOR_SMOKE=','H1_KAFKA_EXISTING_I12=','H1_ICEBERG_I12=','H1_ICEBERG_TOTAL=','H1_ICEBERG_S3_WRITE_READ_DROP=']:
        e.emit(next(line for line in logs.splitlines() if line.startswith(marker)))
    assert e.polaris()==expected_catalog
