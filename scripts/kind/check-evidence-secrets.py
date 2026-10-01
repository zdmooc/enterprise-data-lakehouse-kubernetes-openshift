"""Compare publishable files with live lab credentials without printing their values."""
import base64
from pathlib import Path
import json
import re
import subprocess

if subprocess.check_output(['kubectl', 'config', 'current-context'], text=True).strip() != 'kind-edl-lab':
    raise SystemExit('Wrong Kubernetes context')

needles = set()
for namespace, names in (
    ('edl-data', ('kind-s3', 'polaris-client', 'polaris-bootstrap', 'polaris-s3', 'jupyter-auth')),
    ('edl-observability', ('kind-grafana-admin',)),
):
    for name in names:
        raw = subprocess.check_output(['kubectl', '--context=kind-edl-lab', '-n', namespace,
            'get', 'secret', name, '--ignore-not-found', '-o', 'json'], text=True)
        if not raw.strip():
            continue
        for key, encoded in json.loads(raw).get('data', {}).items():
            if re.search(r'secret|password|credential|token', key, re.I):
                decoded = base64.b64decode(encoded)
                if len(decoded) >= 16:
                    needles.update((decoded, encoded.encode()))

if not needles:
    raise SystemExit('No lab credentials available for comparison')
paths = subprocess.check_output(['git', 'ls-files', '-z', '--cached', '--others', '--exclude-standard']).split(b'\0')
findings = []
for raw in paths:
    if not raw:
        continue
    path = Path(raw.decode('utf-8'))
    if path.is_file():
        content = path.read_bytes()
        if any(needle in content for needle in needles):
            findings.append(str(path))
for path in findings:
    print('[FAIL] Lab credential detected in publishable file:', path)
if findings:
    raise SystemExit(1)
print('[PASS] No known lab credential found in tracked or publishable untracked files')
print('Scope: current lab credential values and their base64 encodings; complementary to pattern/history scanning.')
