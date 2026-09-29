"""Print finding metadata only, never scanner snippets containing potential secrets."""
from collections import Counter
import json
from pathlib import Path

for name in ('files', 'spark', 'jupyter', 's3'):
    report = json.loads(Path(f'.audit/kind/trivy-{name}.json').read_text(encoding='utf-8'))
    findings = []
    for result in report.get('Results', []):
        for kind in ('Vulnerabilities', 'Misconfigurations', 'Secrets'):
            for finding in result.get(kind, []) or []:
                findings.append((kind, finding))
    print(name, 'scan completed:', dict(Counter(f.get('Severity', 'UNKNOWN') for _, f in findings)))
    for kind, finding in findings:
        if finding.get('Severity') not in ('HIGH', 'CRITICAL'):
            continue
        print(kind, finding.get('VulnerabilityID', finding.get('ID', finding.get('RuleID', 'unknown'))),
              finding.get('Severity'), finding.get('PkgName', ''),
              'installed=' + finding.get('InstalledVersion', ''),
              'fixed=' + finding.get('FixedVersion', ''))
print('Scanner execution is not proof of absence of vulnerabilities; findings require explicit review.')
