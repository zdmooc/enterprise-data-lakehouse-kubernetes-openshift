"""Repeatable H1 scans: private JSON under .audit; fixed DB for before/after."""
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / '.audit/kind/h1'
SCANNER = ROOT / '.audit/kind/trivy/trivy.exe'
CACHE = ROOT / '.audit/kind/trivy-cache'
BASE = '377704b8f95b02f8a5c6820cb580abdf28d31e34'
IMAGES = {
    'jupyter': ['edl-jupyter:kind-2026-07-28', 'edl-jupyter:kind-h1-gitpython3.1.59'],
    'spark': ['edl-spark-lakehouse:kind-4.1.3-iceberg1.11', 'edl-spark-lakehouse:kind-h1'],
    's3': ['edl-s3-client:kind-2.31.0', 'edl-s3-client:kind-h1'],
}

phase, component = sys.argv[1:3]
assert phase in ('before', 'after')
RAW.mkdir(parents=True, exist_ok=True)
args = [str(SCANNER)]
if component == 'config':
    dest = RAW / ('config-' + phase)
    files = subprocess.check_output(['git', 'ls-files'], cwd=ROOT, text=True).splitlines()
    for file in files:
        if file.endswith(('.yaml', '.yml')) and (file.startswith('platform/kind/') or '/profiles/kind/' in file):
            target = dest / file
            target.parent.mkdir(parents=True, exist_ok=True)
            content = subprocess.check_output(['git', 'show', BASE + ':' + file], cwd=ROOT) if phase == 'before' else (ROOT / file).read_bytes()
            target.write_bytes(content)
    args += ['config', '--cache-dir', str(CACHE), str(dest)]
else:
    args += ['image', '--cache-dir', str(CACHE), '--skip-db-update', '--skip-java-db-update',
             '--scanners', 'vuln', '--no-progress', '--timeout', '15m', IMAGES[component][phase == 'after']]
args += ['--format', 'json', '--output', str(RAW / (component + '-' + phase + '.json'))]
subprocess.run(args, cwd=ROOT, check=True)
