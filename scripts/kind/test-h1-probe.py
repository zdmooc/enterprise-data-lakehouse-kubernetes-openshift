"""Apply the H1 diagnostic pod rootfs change while preserving its existing PVC."""
import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location('i12', Path(__file__).with_name('test-e2e.py'))
e = importlib.util.module_from_spec(spec)
spec.loader.exec_module(e)
e.guard()
e.OUT = Path(e.BASE) / 'h1-security-hardening'
with e.evidence('probe-local'):
    pvc = e.obj('-n', 'edl-data', 'get', 'pvc', 'kind-contract')
    assert pvc['status']['phase'] == 'Bound'
    before = e.k('-n', 'edl-data', 'exec', 'kind-contract', '--', 'sh', '-c',
                 'find /data -type f -exec sha256sum {} \\;', show=False)
    pod = e.obj('-n', 'edl-data', 'get', 'pod', 'kind-contract')
    readonly = pod['spec']['containers'][0].get('securityContext', {}).get('readOnlyRootFilesystem', False)
    e.emit('BEFORE readOnlyRootFilesystem=' + str(readonly))
    if not readonly:
        # Only this diagnostic pod is replaced. The manifest reuses its Bound PVC.
        e.k('-n', 'edl-data', 'delete', 'pod', 'kind-contract', '--wait=true')
        e.k('apply', '-f', 'platform/kind/contract-probe.yaml')
    e.k('-n', 'edl-data', 'wait', '--for=condition=Ready', 'pod/kind-contract', '--timeout=180s', timeout=190)
    current = e.obj('-n', 'edl-data', 'get', 'pvc', 'kind-contract')
    assert current['metadata']['uid'] == pvc['metadata']['uid']
    assert current['spec']['volumeName'] == pvc['spec']['volumeName']
    assert current['status']['phase'] == 'Bound'
    after = e.k('-n', 'edl-data', 'exec', 'kind-contract', '--', 'sh', '-c',
                'find /data -type f -exec sha256sum {} \\;', show=False)
    assert sorted(before.splitlines()) == sorted(after.splitlines())
    pod = e.obj('-n', 'edl-data', 'get', 'pod', 'kind-contract')
    assert pod['spec']['containers'][0]['securityContext']['readOnlyRootFilesystem'] is True
    e.emit('AFTER rootfs read-only; pod Ready; same Bound PVC UID/volume; stored file hashes unchanged')
