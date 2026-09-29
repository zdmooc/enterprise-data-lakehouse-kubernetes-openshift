"""Read-only final Kind health gate; report names/statuses, never workload contents."""
import json
import subprocess

context = subprocess.check_output(['kubectl', 'config', 'current-context'], text=True).strip()
if context != 'kind-edl-lab':
    raise SystemExit('Wrong Kubernetes context')


def items(kind, *args):
    return json.loads(subprocess.check_output(
        ['kubectl', '--context=kind-edl-lab', 'get', kind, *args, '-o', 'json'],
        text=True))['items']


failures = []
nodes = items('nodes')
if len(nodes) != 3:
    failures.append('Expected exactly three nodes')
for node in nodes:
    if not any(c['type'] == 'Ready' and c['status'] == 'True'
               for c in node['status'].get('conditions', [])):
        failures.append('Node not Ready: ' + node['metadata']['name'])

pods = items('pods', '-A')
for pod in pods:
    status = pod['status']
    name = pod['metadata']['namespace'] + '/' + pod['metadata']['name']
    if status['phase'] == 'Succeeded':
        continue
    ready = any(c['type'] == 'Ready' and c['status'] == 'True'
                for c in status.get('conditions', []))
    if status['phase'] != 'Running' or not ready or pod['metadata'].get('deletionTimestamp'):
        failures.append('Pod not healthy: ' + name + ' ' + status['phase'])

pvcs = items('pvc', '-A')
for pvc in pvcs:
    if pvc['status']['phase'] != 'Bound':
        failures.append('PVC not Bound: ' + pvc['metadata']['name'])

apps = items('applications', '-n', 'argocd')
if len(apps) < 2:
    failures.append('Expected baseline and networking Argo applications')
for app in apps:
    status = app.get('status', {})
    if status.get('sync', {}).get('status') != 'Synced' or status.get('health', {}).get('status') != 'Healthy':
        failures.append('Argo application not Synced/Healthy: ' + app['metadata']['name'])

for failure in failures:
    print('[FAIL]', failure)
if failures:
    raise SystemExit(1)
print(f'[PASS] {len(nodes)} Ready nodes, {len(pods)} healthy/completed pods, '
      f'{len(pvcs)} Bound PVCs, {len(apps)} Synced/Healthy Argo applications')
