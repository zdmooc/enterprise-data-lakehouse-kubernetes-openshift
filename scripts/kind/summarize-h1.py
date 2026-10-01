"""Export finding metadata only. Never export scanner secret matches or snippets."""
from collections import Counter
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / '.audit/kind/h1'
OUT = ROOT / Path((ROOT / '.audit/kind/evidence-dir').read_text().strip()) / 'h1-security-hardening'
OUT.mkdir(exist_ok=True)

def read(name):
    return json.loads((RAW / name).read_text(encoding='utf-8'))

def findings(report):
    return [dict(v, Target=r.get('Target', '')) for r in report.get('Results', [])
            for v in r.get('Vulnerabilities', []) or []]

def identity(v):
    # Versions/filename versions can change on an official bundle upgrade.
    return v['VulnerabilityID'], v['PkgName']

for phase in ('before', 'after'):
    lines = ['H1 image vulnerability finding occurrences (not unique CVEs).',
             'Same frozen Trivy DB and scanner; OS + language dependencies; secrets scanner excluded from images.',
             'DB=' + (ROOT / '.audit/kind/trivy-cache/db/metadata.json').read_text(encoding='utf-8').strip()]
    for component in ('jupyter', 'spark', 's3'):
        report = read(component + '-' + phase + '.json')
        lines.append(component + ': ' + report['ArtifactName'] + ' ' + str(dict(Counter(v['Severity'] for v in findings(report)))))
        lines.append('scanUTC=' + report['CreatedAt'] + '; imageID=' + str(report.get('Metadata', {}).get('ImageID')))
    lines.append('Kafka, Polaris, Trino, Prometheus, Grafana, cluster components, RustFS, BusyBox images: NOT_TESTED (not rescanned in H1).')
    (OUT / ('trivy-' + phase + '-summary.txt')).write_text('\n'.join(lines) + '\n', encoding='utf-8')

for component in ('jupyter', 'spark', 's3'):
    before = findings(read(component + '-before.json'))
    after = findings(read(component + '-after.json'))
    remaining = {identity(v) for v in after}
    lines = ['Classification by CVE/package; FIXED only when absent from every scanned copy in the after image.',
             'UPSTREAM = dependency retained pending supported upstream distribution; DEFERRED = open finding outside targeted changes, not accepted as safe.']
    for v in sorted(before, key=lambda v: (v['VulnerabilityID'], v['PkgName'])):
        if v['Severity'] in ('HIGH', 'CRITICAL') and identity(v) not in remaining:
            lines.append('FIXED ' + v['Severity'] + ' ' + v['VulnerabilityID'] + ' ' + v['PkgName'])
    for v in sorted(after, key=lambda v: (v['Severity'], v['VulnerabilityID'], v['PkgName'])):
        if v['Severity'] not in ('HIGH', 'CRITICAL'):
            continue
        upstream = component == 'spark' and ('netty' in v['PkgName'] or 'derby' in v['PkgName'])
        state = 'UPSTREAM' if upstream else 'DEFERRED'
        lines.append(' '.join([state, v['Severity'], v['VulnerabilityID'], v['PkgName'],
                              'installed=' + v['InstalledVersion'], 'fix=' + v.get('FixedVersion', ''),
                              'path=' + v.get('PkgPath', v.get('Target', ''))]))
    (OUT / (('s3-client' if component == 's3' else component) + '-scan.txt')).write_text('\n'.join(dict.fromkeys(lines)) + '\n', encoding='utf-8')

lines = ['Kind manifest scope only; excludes CRC/OpenShift profiles and intentional negative fixtures.']
for phase in ('before', 'after'):
    report = read('config-' + phase + '.json')
    counts = Counter()
    for result in report.get('Results', []):
        for v in result.get('Misconfigurations', []) or []:
            counts[v['ID']] += 1
            lines.append(phase + ' ' + result['Target'] + ' ' + v['ID'] + ' ' + v['Severity'])
    lines.append(phase + ' TOTAL=' + str(dict(counts)))
(OUT / 'config-scan.txt').write_text('\n'.join(lines) + '\n', encoding='utf-8')
