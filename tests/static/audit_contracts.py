"""Offline checks only: parse/render files and run probes against a fake CLI.

Usage: python tests/static/audit_contracts.py [--root PATH] [--charts PATH]
Requires PyYAML, Bash, kubectl (kustomize only), Helm (template only).
No kubeconfig, network, container engine or running cluster is used.
"""
import argparse
import ast
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile

import yaml

parser = argparse.ArgumentParser()
parser.add_argument('--root', type=Path, default=Path('.'))
parser.add_argument('--charts', type=Path, required=True)
args = parser.parse_args()
root = args.root.resolve()
charts = args.charts.resolve()
bash = os.environ.get('BASH_BIN', 'bash')
failures = []
checks = 0

def check(condition, message):
    global checks
    checks += 1
    if not condition:
        failures.append(message)
        print('FAIL:', message)

def read(path):
    return (root / path).read_text(encoding='utf-8-sig')

def command(argv):
    result = subprocess.run(argv, cwd=root, capture_output=True, text=True, encoding='utf-8', errors='replace')
    check(result.returncode == 0, ' '.join(str(x) for x in argv) + ': ' + result.stderr[:300])
    return result.stdout

files = [p for p in root.rglob('*') if p.is_file() and not any(x in p.relative_to(root).parts for x in ['.git', '.audit', '__pycache__'])]
for p in files:
    if p.suffix in ['.yaml', '.yml']:
        try:
            list(yaml.safe_load_all(p.read_text(encoding='utf-8-sig')))
            check(True, str(p))
        except yaml.YAMLError as e:
            check(False, f'{p}: {e}')
    elif p.suffix == '.json':
        json.loads(p.read_text(encoding='utf-8-sig'))
        check(True, str(p))
    elif p.suffix == '.py':
        ast.parse(p.read_text(encoding='utf-8-sig'))
        check(True, str(p))
    elif p.suffix == '.sh':
        command([bash, '-n', str(p)])

rendered = {}
for p in files:
    if p.name == 'kustomization.yaml':
        rel = str(p.parent.relative_to(root)).replace('\\', '/')
        rendered[rel] = list(yaml.safe_load_all(command(['kubectl', 'kustomize', str(p.parent)])))

def objects(path):
    return [x for x in yaml.safe_load_all(read(path)) if x]

trino = list(yaml.safe_load_all(command(['helm', 'template', 'edl-trino', str(charts / 'trino'), '-n', 'edl-data', '-f', 'data-platform/trino/values-crc.yaml', '-f', 'data-platform/trino/values-lakehouse.yaml'])))
polaris = list(yaml.safe_load_all(command(['helm', 'template', 'edl-polaris', str(charts / 'polaris'), '-n', 'edl-data', '--kube-version', '1.33.0', '-f', 'data-platform/catalog/polaris/values-crc.yaml'])))
services = {x['metadata']['name']: x for x in trino + polaris if x and x['kind'] == 'Service'}
for host, port in [('edl-trino', 8080), ('edl-polaris', 8181)]:
    check(host in services and any(p['port'] == port for p in services[host]['spec']['ports']), f'E2E service {host}:{port} exists in chart render')
for obj in trino:
    if obj and obj['kind'] == 'ConfigMap' and 'config.properties' in (obj.get('data') or {}):
        config = obj['data']['config.properties']
        check('query.max-memory-per-node=256MB' in config, f"512M heap has bounded query memory: {obj['metadata']['name']}")

for obj in objects('data-platform/spark/openshift/buildconfig.yaml') + objects('data-platform/lakehouse/openshift/buildconfig.yaml') + objects('data-platform/jupyter/openshift/buildconfig.yaml'):
    if obj['kind'] != 'BuildConfig':
        continue
    context = root / obj['spec']['source']['contextDir']
    dockerfile = context / obj['spec']['strategy']['dockerStrategy']['dockerfilePath']
    for source, destination in re.findall(r'^COPY\s+(\S+)\s+(\S+)', dockerfile.read_text(), re.M):
        check((context / source).exists(), f"{obj['metadata']['name']}: COPY source {source} exists in context")
        if obj['metadata']['name'] == 'edl-jupyter':
            check(not destination.startswith('/home/jovyan/work'), 'Jupyter samples survive PVC mount')

check('edl.network/kafka-client=true' in read('scripts/produce-synthetic-transactions.sh'), 'JSON producer matches Kafka egress selector')
check('TOPIC="transactions.raw"' not in read('scripts/test-kafka.sh'), 'Kafka smoke does not contaminate JSON topic')
check('spark.kubernetes.driverEnv.POLARIS_CREDENTIAL=' not in read('data-platform/lakehouse/openshift/spark-submit-job.yaml'), 'Spark credential uses secretKeyRef rather than literal driver env')
check('vended-credentials-enabled=false' in read('data-platform/trino/values-lakehouse.yaml'), 'Non-STS S3 profile disables vending')
check('"stsUnavailable":True' in read('scripts/bootstrap-polaris-catalog.sh'), 'Non-STS catalog explicitly configured')
check('echo "Token:' not in read('scripts/deploy-jupyter-crc.sh'), 'Jupyter token not printed into E2E evidence')
for item in rendered.get('data-platform/kafka/profiles/multinode', []):
    if item and item['kind'] == 'KafkaTopic':
        check(item['spec']['replicas'] == 3, f"Multi-node topic RF=3: {item['metadata']['name']}")

# Evaluate both sides of selected NetworkPolicy flows against rendered objects.
policies = [x for key in ['platform/baseline/overlays/openshift-crc', 'data-platform/networking/base', 'data-platform/kafka/profiles/crc', 'observability/openshift'] for x in rendered.get(key, []) if x and x['kind'] == 'NetworkPolicy']
policies += [x for x in trino if x and x['kind'] == 'NetworkPolicy']

def matches(selector, labels):
    if any(labels.get(k) != v for k, v in selector.get('matchLabels', {}).items()):
        return False
    for term in selector.get('matchExpressions', []):
        key, op, vals = term['key'], term['operator'], term.get('values', [])
        if op == 'In' and labels.get(key) not in vals: return False
        if op == 'NotIn' and labels.get(key) in vals: return False
        if op == 'Exists' and key not in labels: return False
        if op == 'DoesNotExist' and key in labels: return False
    return True

def permits(direction, local, peer, port, protocol='TCP'):
    selected = [x['spec'] for x in policies if x['metadata'].get('namespace') == local[0] and matches(x['spec']['podSelector'], local[1]) and direction in x['spec'].get('policyTypes', ['Ingress'])]
    if not selected: return True
    for policy in selected:
        for rule in policy.get(direction.lower(), []):
            ports = rule.get('ports', [])
            if ports and not any(p.get('protocol', 'TCP') == protocol and p.get('port') == port for p in ports): continue
            peers = rule.get('to' if direction == 'Egress' else 'from', [])
            if not peers: return True
            for item in peers:
                if 'ipBlock' in item:
                    if peer[0] == 'external' and item['ipBlock']['cidr'] == '0.0.0.0/0': return True
                    continue
                if 'namespaceSelector' in item:
                    if not matches(item['namespaceSelector'], {'kubernetes.io/metadata.name': peer[0]}): continue
                elif local[0] != peer[0]: continue
                if matches(item.get('podSelector', {}), peer[1]): return True
    return False

driver = ('edl-data', {'spark-role': 'driver', 'edl.network/api-client': 'true'})
executor = ('edl-data', {'spark-role': 'executor'})
producer = ('edl-data', {'edl.network/kafka-client': 'true'})
kafka = ('edl-data', {'strimzi.io/cluster': 'edl-kafka'})
trino_pod = ('edl-data', {'app.kubernetes.io/name': 'trino', 'app.kubernetes.io/instance': 'edl-trino', 'trino.io/network-policy-protection': 'enabled'})
catalog = ('edl-data', {'app.kubernetes.io/name': 'polaris'})
monitor = ('openshift-user-workload-monitoring', {})
for source, target, port in [(producer,kafka,9092),(driver,kafka,9092),(driver,catalog,8181),(executor,driver,7078),(driver,executor,7079),(executor,driver,7079),(trino_pod,catalog,8181),(monitor,trino_pod,8080),(monitor,kafka,9404)]:
    check(permits('Egress',source,target,port) and permits('Ingress',target,source,port), f'Network flow {source} -> {target}:{port}')
for source in [driver, executor, trino_pod, catalog]:
    check(permits('Egress',source,('external',{}),443), f'S3 HTTPS egress from {source[1]}')
check(permits('Egress', driver, ('openshift-dns',{}),5353,'UDP'), 'OpenShift DNS egress 5353/UDP')
check(not permits('Ingress',catalog,('other-poc',{}),8181), 'Other POC namespace cannot reach catalog')

# Shell behaviour tests: PATH contains a fake oc/kubectl and Unix utilities only.
# The fake CLI is generated locally and cannot fall through to a real CLI.
mock = '''#!/usr/bin/env bash
case "$*" in
  *api-resources*) echo 'routes route.openshift.io'; exit 0;;
  *'create ns'*) [ "${MOCK_MODE:-}" != existing ]; exit $?;;
  *'delete ns'*) [ "${MOCK_MODE:-}" != existing ] || echo UNEXPECTED_NAMESPACE_DELETE >>"$MOCK_LOG"; exit 0;;
  *'auth can-i list pods'*) echo yes; exit 0;;
  *'auth can-i'*) echo no; exit 1;;
  *'.status.sync.status'*) echo Synced; exit 0;;
  *'.status.health.status'*) echo "${MOCK_HEALTH:-Healthy}"; exit 0;;
  *'pod-versioned-allowed.yaml'*) exit 0;;
  *'pod-latest-denied.yaml'*)
    if [ "${MOCK_MODE:-}" = admission ]; then echo 'denied by disallow-latest-images' >&2; else echo 'connection refused' >&2; fi
    exit 1;;
  *'--field-selector=status.phase=Running'*) echo replacement-pod; exit 0;;
  *'.metadata.ownerReferences'*) echo ReplicaSet/example; exit 0;;
  *'get pod -l'*) echo original-pod; exit 0;;
  *'wait pod -l'*) [ "${MOCK_MODE:-}" != not-ready ]; exit $?;;
  *'exec'*'EDL_CURL_EXIT'*)
    [ "${MOCK_MODE:-}" != api-error ] || exit 1
    echo "EDL_CURL_EXIT=${MOCK_CURL:-28}"; exit 0;;
  *'apply'*'-f -'*) cat >/dev/null; exit 0;;
esac
exit 0
'''

def posix(path):
    s = str(path).replace('\\','/')
    return '/' + s[0].lower() + s[2:] if len(s)>1 and s[1] == ':' else s

with tempfile.TemporaryDirectory(prefix='edl-offline-') as tmp:
    bindir = Path(tmp)
    for name, content in [('oc',mock),('kubectl',mock),('sleep','#!/usr/bin/env bash\nexit 0\n')]:
        f = bindir / name
        f.write_text(content, encoding='utf-8', newline='\n')
        f.chmod(0o755)
    def probe(script, expected, **env):
        log = bindir / 'calls.log'
        log.write_text('', encoding='utf-8')
        result = subprocess.run([bash,'-c', 'export PATH=' + shlex.quote(posix(bindir)+':/usr/bin:/bin') + '; exec bash ' + shlex.quote(script)], cwd=root, env={**os.environ, 'MOCK_LOG': posix(log), **env}, capture_output=True, text=True)
        check((result.returncode == 0) == expected, f'{script} fake CLI {env}: exit={result.returncode}; {result.stdout[-150:]} {result.stderr[-100:]}')
        check('UNEXPECTED_NAMESPACE_DELETE' not in log.read_text(), f'{script}: existing namespace preserved')
    for code in ['0','6','7','22']:
        probe('scripts/test-networkpolicy.sh',False,MOCK_CURL=code)
    probe('scripts/test-networkpolicy.sh',True,MOCK_CURL='28')
    probe('scripts/test-networkpolicy.sh',False,MOCK_MODE='api-error')
    probe('scripts/test-networkpolicy.sh',False,MOCK_MODE='existing')
    for script in ['test-dns.sh','test-pvc.sh','test-rbac.sh']:
        probe('scripts/'+script,False,MOCK_MODE='existing')
    probe('scripts/test-rbac.sh',True)
    probe('scripts/verify-baseline.sh',True)
    probe('scripts/validate-baseline.sh',True)
    probe('scripts/bootstrap-gitops.sh',False,MOCK_HEALTH='Missing')
    probe('scripts/bootstrap-gitops.sh',True,MOCK_HEALTH='Healthy')
    probe('scripts/test-security-policies.sh',False,MOCK_MODE='network-error')
    probe('scripts/test-security-policies.sh',True,MOCK_MODE='admission')
    probe('scripts/chaos-delete-pod.sh',False,MOCK_MODE='not-ready',CONFIRM_CHAOS='yes',SELECTOR='app=edl-jupyter')
    probe('scripts/chaos-delete-pod.sh',True,MOCK_MODE='ready',CONFIRM_CHAOS='yes',SELECTOR='app=edl-jupyter')

print(f'Offline audit: {checks} checks, {len(failures)} failures. No runtime evidence.')
raise SystemExit(bool(failures))
