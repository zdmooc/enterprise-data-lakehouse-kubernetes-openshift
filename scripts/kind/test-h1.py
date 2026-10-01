"""H1 read-only regressions using I12's verified event; never produce or replay data."""
import importlib.util
import json
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location('i12', Path(__file__).with_name('test-e2e.py'))
e2e = importlib.util.module_from_spec(spec)
spec.loader.exec_module(e2e)
source = e2e.OUT
e2e.guard()
e2e.OUT = Path(e2e.BASE) / 'h1-security-hardening'
e2e.OUT.mkdir(exist_ok=True)
e2e.load = lambda name: json.loads((source / (name + '.json')).read_text())

if len(sys.argv) > 1 and sys.argv[1] == 'initial':
    e2e.health('health-before')
    sys.exit(0)

with e2e.evidence('regression'):
    e2e.emit('H1 checkpoint=' + (sys.argv[1] if len(sys.argv) > 1 else 'final'))
    catalog = e2e.polaris()
    assert catalog == e2e.load('polaris-after'), 'I12 catalog/snapshot changed'
    e2e.validate()
    e2e.k('-n', 'edl-data', 'exec', 'deployment/edl-jupyter', '--', 'python', '-c',
          'import git,os,urllib.request; from pathlib import Path; '
          'assert git.__version__ == "3.1.59"; print("GitPython="+git.__version__); '
          'r=urllib.request.Request("http://127.0.0.1:8888/api/status",headers={"Authorization":"token "+os.environ["JUPYTER_TOKEN"].strip()}); '
          'assert urllib.request.urlopen(r,timeout=15).status==200; '
          'assert Path("/home/jovyan/work/kind-volume-proof.txt").read_text()=="kind-jupyter-persistence"; '
          'print("Jupyter authenticated HTTP and persistent marker PASS")')
    kernel_test = '''
from jupyter_client import KernelManager
import time
km=KernelManager(kernel_name='python3')
km.start_kernel(cwd='/home/jovyan/work')
client=km.client(); client.start_channels()
try:
    client.wait_for_ready(timeout=60)
    code="import os,trino; c=trino.dbapi.connect(host=os.environ['TRINO_HOST'],port=8080,user='data-analyst',catalog='polaris',schema='analytics'); q=c.cursor(); q.execute(\\\"SELECT eventId FROM transactions WHERE eventId='E2E-I12-20260930T051236Z-a0adb24c8c95'\\\"); rows=q.fetchall(); assert rows==[['E2E-I12-20260930T051236Z-a0adb24c8c95']]; print('H1_NOTEBOOK_KERNEL_I12=PASS')"
    msgid=client.execute(code)
    passed=False
    while True:
        msg=client.get_iopub_msg(timeout=60)
        if msg.get('parent_header',{}).get('msg_id')!=msgid: continue
        if msg['msg_type']=='error': raise RuntimeError(msg['content']['ename'])
        if msg['msg_type']=='stream' and 'H1_NOTEBOOK_KERNEL_I12=PASS' in msg['content']['text']: passed=True
        if msg['msg_type']=='status' and msg['content']['execution_state']=='idle': break
    assert passed
    print('H1_NOTEBOOK_KERNEL_I12=PASS')
finally:
    client.stop_channels(); km.shutdown_kernel(now=True)
'''
    e2e.k('-n', 'edl-data', 'exec', 'deployment/edl-jupyter', '--', 'python', '-c', kernel_test, timeout=180)
    if len(sys.argv) < 2 or sys.argv[1] == 'final':
        e2e.finish()
