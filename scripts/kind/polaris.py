"""Kind-only credential/bootstrap helper. Secret values never reach stdout or argv."""
import base64
import json
import secrets
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request


def guard():
    current = subprocess.check_output(['kubectl', 'config', 'current-context'], text=True).strip()
    if current != 'kind-edl-lab':
        raise SystemExit('Wrong Kubernetes context')


def k(*args, payload=None):
    guard()
    return subprocess.check_output(
        ['kubectl', '--context=kind-edl-lab', '-n', 'edl-data', *args],
        input=payload, text=True,
    )


def secret(name):
    raw = k('get', 'secret', name, '--ignore-not-found', '-o', 'json')
    return {key: base64.b64decode(value).decode() for key, value in
            json.loads(raw).get('data', {}).items()} if raw.strip() else None


def ensure_secret(name, values):
    existing = secret(name)
    if existing is not None:
        if existing != values:
            raise SystemExit(f'Existing secret {name} differs; refusing implicit rotation')
        return
    k('create', '-f', '-', payload=json.dumps({
        'apiVersion': 'v1', 'kind': 'Secret',
        'metadata': {'name': name, 'namespace': 'edl-data'}, 'stringData': values,
    }))


guard()
s3 = secret('kind-s3')
if not s3:
    raise SystemExit('Kind S3 credentials missing')
if sys.argv[1] == 'secrets':
    existing = secret('polaris-client')
    password = existing['CLIENT_SECRET'] if existing else secrets.token_hex(24)
    ensure_secret('polaris-client', {'CLIENT_ID': 'root', 'CLIENT_SECRET': password,
                                   'POLARIS_CREDENTIAL': f'root:{password}'})
    ensure_secret('polaris-bootstrap', {'credentials': f'POLARIS,root,{password}'})
    ensure_secret('polaris-s3', {'endpoint': s3['S3_ENDPOINT'],
        'region': s3['AWS_DEFAULT_REGION'], 'accessKeyId': s3['AWS_ACCESS_KEY_ID'],
        'secretAccessKey': s3['AWS_SECRET_ACCESS_KEY']})
    print('[PASS] Polaris credentials available in Kubernetes Secrets only')
elif sys.argv[1] == 'bootstrap':
    client = secret('polaris-client')
    # A previous notebook/user forward may still own 18181 after pod replacement.
    # Use an available loopback port for this short-lived recovery operation.
    with socket.socket() as listener:
        listener.bind(('127.0.0.1', 0))
        port = listener.getsockname()[1]
    pf = subprocess.Popen(['kubectl', '--context=kind-edl-lab', '-n', 'edl-data',
        'port-forward', 'svc/edl-polaris', f'{port}:8181', '--address=127.0.0.1'],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        root = f'http://127.0.0.1:{port}'
        basic = base64.b64encode(f"{client['CLIENT_ID']}:{client['CLIENT_SECRET']}".encode()).decode()
        request = urllib.request.Request(root + '/api/catalog/v1/oauth/tokens',
            data=urllib.parse.urlencode({'grant_type': 'client_credentials',
                                        'scope': 'PRINCIPAL_ROLE:ALL'}).encode(),
            headers={'Authorization': 'Basic ' + basic, 'Polaris-Realm': 'POLARIS'})
        for attempt in range(30):
            if pf.poll() is not None:
                raise SystemExit('Polaris port-forward exited before authentication')
            try:
                with urllib.request.urlopen(request, timeout=5) as response:
                    token = json.load(response)['access_token']
                break
            except OSError:
                if attempt == 29 or pf.poll() is not None:
                    raise SystemExit('Polaris authentication/port-forward failed')
                time.sleep(1)
        headers = {'Authorization': 'Bearer ' + token, 'Polaris-Realm': 'POLARIS',
                   'Content-Type': 'application/json'}

        def api(path, method='GET', data=None):
            req = urllib.request.Request(root + '/api/management/v1/' + path,
                method=method, headers=headers,
                data=json.dumps(data).encode() if data is not None else None)
            try:
                with urllib.request.urlopen(req, timeout=30) as response:
                    raw = response.read()
                    return json.loads(raw) if raw else None
            except urllib.error.HTTPError as exc:
                if exc.code == 409 and method == 'POST':
                    return None
                raise SystemExit(f'Polaris {method} {path}: HTTP {exc.code}')

        catalog = {'name': 'quickstart_catalog', 'type': 'INTERNAL', 'readOnly': False,
            'properties': {'default-base-location': f"s3://{s3['S3_BUCKET']}/curated/"},
            'storageConfigInfo': {'storageType': 'S3',
                'allowedLocations': [f"s3://{s3['S3_BUCKET']}/curated/"],
                'stsUnavailable': True, 'endpoint': s3['S3_ENDPOINT'],
                'endpointInternal': s3['S3_ENDPOINT'], 'pathStyleAccess': True,
                'region': s3['AWS_DEFAULT_REGION']}}
        api('catalogs', 'POST', {'catalog': catalog})
        current = api('catalogs/quickstart_catalog')
        current = current.get('catalog', current)
        for section in ('properties', 'storageConfigInfo'):
            for key, value in catalog[section].items():
                if current.get(section, {}).get(key) != value:
                    raise SystemExit(f'Catalog contract mismatch: {section}.{key}')
        api('catalogs/quickstart_catalog/catalog-roles/catalog_admin/grants', 'PUT',
            {'type': 'catalog', 'privilege': 'CATALOG_MANAGE_CONTENT'})
        api('principal-roles/service_admin/catalog-roles/quickstart_catalog', 'PUT',
            {'catalogRole': {'name': 'catalog_admin'}})
        print('[PASS] Polaris authentication, catalog storage contract and grants verified')
        print('Catalog: quickstart_catalog; storage: s3://edl-lab/curated/')
        print('LAB ONLY / IN-MEMORY METADATA / NOT DURABLE / NOT PRODUCTION HA')
    finally:
        pf.terminate()
        pf.wait(timeout=15)
else:
    raise SystemExit('Expected secrets or bootstrap')
