"""Require live Kafka/Trino scrape targets and loaded application alert rules."""
import base64
import json
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request

if subprocess.check_output(['kubectl', 'config', 'current-context'], text=True).strip() != 'kind-edl-lab':
    raise SystemExit('Wrong Kubernetes context')
pf = subprocess.Popen(['kubectl', '--context=kind-edl-lab', '-n', 'edl-observability',
    'port-forward', 'svc/edl-monitoring-prometheus', '19090:9090', '--address=127.0.0.1'],
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
try:
    def get(path):
        with urllib.request.urlopen('http://127.0.0.1:19090/api/v1/' + path, timeout=10) as response:
            result = json.load(response)
            assert result['status'] == 'success'
            return result['data']

    required = {'kafka', 'kafka-exporter', 'trino-coordinator', 'trino-worker'}
    targets = []
    for attempt in range(60):
        try:
            targets = get('targets?state=active')['activeTargets']
            found = set()
            for target in targets:
                pool = target['scrapePool']
                if target['health'] != 'up':
                    continue
                if '/edl-kafka-metrics/' in pool and target.get('labels', {}).get('pod') == 'edl-kafka-dual-role-0':
                    found.add('kafka')
                if '/edl-kafka-exporter/' in pool: found.add('kafka-exporter')
                if '/edl-trino-coordinator/' in pool: found.add('trino-coordinator')
                if '/edl-trino-worker/' in pool: found.add('trino-worker')
            if found == required:
                break
        except urllib.error.URLError:
            if pf.poll() is not None:
                raise SystemExit('Prometheus port-forward failed')
        time.sleep(5)
    else:
        for target in targets:
            print(target['scrapePool'], target['health'], target.get('lastError', ''))
        raise SystemExit('Required application scrape targets are missing or DOWN')
    for target in targets:
        print(target['scrapePool'], target['health'], target.get('lastError', ''))
    groups = get('rules')['groups']
    names = {rule['name'] for group in groups for rule in group['rules']}
    expected = {'EDLKafkaConsumerLagHigh', 'EDLKafkaUnderReplicatedPartition',
                'EDLPodRestartBurst', 'EDLPVCNearlyFull'}
    assert expected <= names, f'Missing rules: {expected - names}'
    print('Loaded application rules:', ', '.join(sorted(expected)))
    for group in groups:
        for rule in group['rules']:
            if rule['name'] in expected:
                print('Rule:', rule['name'], 'health=' + rule.get('health', 'unknown'),
                      'state=' + rule.get('state', 'unknown'))
    for metric in ('kube_pod_status_ready', 'kube_pod_container_status_restarts_total',
                   'kafka_consumergroup_lag', 'kafka_topic_partition_under_replicated_partition',
                   'trino_execution_name_QueryManager_RunningQueries',
                   'kubelet_volume_stats_capacity_bytes'):
        series = get('query?' + urllib.parse.urlencode({'query': metric}))['result']
        print('Metric series:', metric, len(series))
    assert get('query?' + urllib.parse.urlencode({'query': 'kube_pod_status_ready{namespace="edl-data"}'}))['result'], 'No workload metrics available'
    print('[PASS] Kafka, exporter, Trino coordinator and worker targets UP; alert rules loaded')
finally:
    pf.terminate()
    pf.wait(timeout=15)

auth = json.loads(subprocess.check_output(['kubectl', '--context=kind-edl-lab',
    '-n', 'edl-observability', 'get', 'secret', 'kind-grafana-admin', '-o', 'json'], text=True))['data']
credentials = ':'.join(base64.b64decode(auth[key]).decode() for key in ('username', 'password'))
headers = {'Authorization': 'Basic ' + base64.b64encode(credentials.encode()).decode()}
pf = subprocess.Popen(['kubectl', '--context=kind-edl-lab', '-n', 'edl-observability',
    'port-forward', 'svc/edl-monitoring-grafana', '13000:80', '--address=127.0.0.1'],
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
try:
    expected = {'EDL Data Pipeline', 'Enterprise Data Lakehouse - Platform Overview'}
    for attempt in range(36):
        try:
            req = urllib.request.Request('http://127.0.0.1:13000/api/search?query=EDL', headers=headers)
            with urllib.request.urlopen(req, timeout=10) as response:
                dashboards = json.load(response)
            # The overview title starts with Enterprise, so query the entire list.
            req = urllib.request.Request('http://127.0.0.1:13000/api/search', headers=headers)
            with urllib.request.urlopen(req, timeout=10) as response:
                titles = {item['title'] for item in json.load(response)}
            if expected <= titles:
                req = urllib.request.Request('http://127.0.0.1:13000/api/datasources', headers=headers)
                with urllib.request.urlopen(req, timeout=10) as response:
                    sources = json.load(response)
                source = next(s for s in sources if s['type'] == 'prometheus' and s['isDefault'])
                req = urllib.request.Request('http://127.0.0.1:13000/api/datasources/uid/' + source['uid'] + '/health', headers=headers)
                with urllib.request.urlopen(req, timeout=15) as response:
                    health = json.load(response)
                assert health['status'] == 'OK', 'Grafana Prometheus datasource is unhealthy'
                print('[PASS] Grafana authenticated API, healthy Prometheus datasource and both repository dashboards available')
                break
        except urllib.error.URLError:
            if pf.poll() is not None:
                raise SystemExit('Grafana port-forward failed')
        time.sleep(5)
    else:
        raise SystemExit('Grafana repository dashboards not available')
finally:
    pf.terminate()
    pf.wait(timeout=15)
