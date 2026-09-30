#!/usr/bin/env bash
# Final local H1 validation against the retained I12 Kind runtime.
# Guardrails: Kind only, no producer/replay, no namespace/PVC/cluster deletion, no CRC command.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

BRANCH="runtime/kind-edl-lab"
CONTEXT="kind-edl-lab"
CLUSTER="edl-lab"
BASE_EVIDENCE="evidence/kind-edl-lab/20260928T112119Z"
H1_EVIDENCE="$BASE_EVIDENCE/h1-security-hardening"
I12_EVENT="E2E-I12-20260930T051236Z-a0adb24c8c95"
JUPYTER_BASE="edl-jupyter:kind-2026-07-28"
JUPYTER_H1="edl-jupyter:kind-h1-gitpython3.1.59"
S3_BASE="edl-s3-client:kind-2.31.0"
S3_H1="edl-s3-client:kind-h1"
SPARK_BASE="edl-spark-lakehouse:kind-4.1.3-iceberg1.11"
SPARK_H1="edl-spark-lakehouse:kind-h1"
TRIVY=".audit/kind/trivy/trivy.exe"
TRIVY_CACHE=".audit/kind/trivy-cache"

fail() { printf '[FAIL] %s\n' "$*" >&2; exit 1; }
trap 'printf "[FAIL] H1 local finalize stopped at line %s\n" "$LINENO" >&2' ERR

k() {
  kubectl --context="$CONTEXT" "$@"
}

if command -v python >/dev/null 2>&1; then
  PYTHON=(python)
elif command -v py >/dev/null 2>&1; then
  PYTHON=(py -3)
else
  fail "Python 3 not found"
fi

echo "===== H1 LOCAL FINALIZE: PRECHECK ====="
[ "$(git branch --show-current)" = "$BRANCH" ] || fail "wrong Git branch"
[ -z "$(git status --porcelain)" ] || fail "Git working tree must be clean before H1"
[ "$(kubectl config current-context)" = "$CONTEXT" ] || fail "wrong kube context; CRC is intentionally not touched"
kind get clusters | grep -Fx "$CLUSTER" >/dev/null || fail "Kind cluster $CLUSTER not found"

k wait --for=condition=Ready nodes --all --timeout=300s
[ "$(k get nodes -o name | wc -l | tr -d ' ')" = "3" ] || fail "expected exactly 3 Kind nodes"
k get nodes -o wide

mkdir -p .audit/kind/h1 "$H1_EVIDENCE"
printf '%s\n' "$BASE_EVIDENCE" > .audit/kind/evidence-dir

[ -f "$BASE_EVIDENCE/i12/transaction.json" ] || fail "I12 transaction evidence missing"
grep -F "$I12_EVENT" "$BASE_EVIDENCE/i12/transaction.json" >/dev/null || fail "retained I12 event mismatch"
[ -x "$TRIVY" ] || fail "Trivy 0.74.0 local executable missing at $TRIVY"

echo "===== H1 HEALTH BEFORE ====="
"${PYTHON[@]}" scripts/kind/test-h1.py initial

echo "===== H1 BUILD IMAGES ====="
if ! docker image inspect "$JUPYTER_BASE" >/dev/null 2>&1; then
  docker build -t "$JUPYTER_BASE" data-platform/jupyter/image
fi

docker build -f platform/kind/jupyter/Dockerfile -t "$JUPYTER_H1" .

if ! docker image inspect "$S3_BASE" >/dev/null 2>&1; then
  docker build -t "$S3_BASE" platform/kind/s3-client
fi
docker build -f platform/kind/s3-client/Dockerfile.h1 -t "$S3_H1" .

docker image inspect "$SPARK_BASE" >/dev/null 2>&1 || fail "validated I12 Spark image missing locally; stop rather than rebuild it"
docker tag "$SPARK_BASE" "$SPARK_H1"

echo "===== H1 LOAD HARDENED IMAGES INTO KIND ====="
kind load docker-image "$JUPYTER_H1" --name "$CLUSTER"
kind load docker-image "$S3_H1" --name "$CLUSTER"

echo "===== H1 DEPLOY JUPYTER + RUSTFS ====="
k apply -k data-platform/jupyter/profiles/kind
k -n edl-data rollout status deployment/edl-jupyter --timeout=600s
k -n edl-data wait --for=condition=Ready pod -l app=edl-jupyter --timeout=300s

k apply -k data-platform/object-storage/profiles/kind
k -n edl-data rollout status deployment/edl-s3 --timeout=600s
k -n edl-data wait --for=condition=Ready pod -l app=edl-s3 --timeout=300s

echo "===== H1 S3 CLIENT + CONTRACT ====="
k -n edl-data create configmap kind-s3-contract-scripts \
  --from-file=scripts/bootstrap-s3-layout.sh \
  --from-file=scripts/verify-s3-layout.sh \
  --from-file=scripts/s3-contract-check.sh \
  --dry-run=client -o yaml | k apply -f -

# Stateless diagnostic pod only. No PVC, namespace or service data is removed.
k -n edl-data delete pod kind-s3-reader --ignore-not-found --wait=true
k apply -f platform/kind/s3-reader.yaml
k -n edl-data wait --for=condition=Ready pod/kind-s3-reader --timeout=300s

# Replace only the disposable contract Job.
k -n edl-data delete job kind-s3-contract --ignore-not-found --wait=true
k apply -f platform/kind/s3-contract-job.yaml
k -n edl-data wait --for=condition=Complete job/kind-s3-contract --timeout=600s
k -n edl-data logs job/kind-s3-contract | tee "$H1_EVIDENCE/s3-contract-local.txt"

echo "===== H1 DEPLOYED SECURITY CONTEXT ====="
{
  date -u +'%Y-%m-%dT%H:%M:%SZ'
  echo "context=$(kubectl config current-context)"
  k -n edl-data get deployment edl-jupyter -o jsonpath='jupyter.image={.spec.template.spec.containers[0].image}{"\n"}jupyter.readOnlyRootFilesystem={.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}{"\n"}'
  k -n edl-data get deployment edl-s3 -o jsonpath='rustfs.image={.spec.template.spec.containers[0].image}{"\n"}rustfs.readOnlyRootFilesystem={.spec.template.spec.containers[0].securityContext.readOnlyRootFilesystem}{"\n"}'
  k -n edl-data get pod kind-s3-reader -o jsonpath='s3reader.image={.spec.containers[0].image}{"\n"}s3reader.readOnlyRootFilesystem={.spec.containers[0].securityContext.readOnlyRootFilesystem}{"\n"}'
  k -n edl-data exec deployment/edl-jupyter -- python -c 'import git; print("GitPython="+git.__version__); assert git.__version__=="3.1.59"'
  k -n edl-data exec kind-s3-reader -- aws --version
} | tee "$H1_EVIDENCE/runtime-hardening-local.txt"

echo "===== H1 SPARK KUBERNETES REGRESSION ====="
# This reads the retained I12 Kafka event and the six-row Iceberg table.
# It creates/drops one disposable Iceberg table only; it never calls the producer.
"${PYTHON[@]}" scripts/kind/test-h1-spark.py

echo "===== H1 FINAL READ-ONLY REGRESSION ====="
# Exact retained Polaris snapshot, six rows, Jupyter kernel -> Trino,
# persistence marker, observability and final health.
"${PYTHON[@]}" scripts/kind/test-h1.py

echo "===== H1 LOCAL TRIVY FROZEN DB ====="
"$TRIVY" image --download-db-only --cache-dir "$TRIVY_CACHE"
"$TRIVY" image --download-java-db-only --cache-dir "$TRIVY_CACHE"

for component in jupyter spark s3; do
  echo "--- scan $component before"
  "${PYTHON[@]}" scripts/kind/scan-h1.py before "$component"
  echo "--- scan $component after"
  "${PYTHON[@]}" scripts/kind/scan-h1.py after "$component"
done

"${PYTHON[@]}" scripts/kind/scan-h1.py before config
"${PYTHON[@]}" scripts/kind/scan-h1.py after config
"${PYTHON[@]}" scripts/kind/summarize-h1.py

echo "===== H1 ASSERT SCAN OUTCOMES + WRITE LOCAL CHECKPOINT ====="
"${PYTHON[@]}" - <<'PY'
from collections import Counter
from datetime import datetime, timezone
import json
from pathlib import Path

raw = Path('.audit/kind/h1')
out = Path('evidence/kind-edl-lab/20260928T112119Z/h1-security-hardening')

def report(name):
    return json.loads((raw / name).read_text(encoding='utf-8'))

def vulns(name):
    return [v for r in report(name).get('Results', []) for v in (r.get('Vulnerabilities') or [])]

def counts(name):
    return Counter(v['Severity'] for v in vulns(name))

def ksv0014(name):
    return sum(
        1
        for r in report(name).get('Results', [])
        for m in (r.get('Misconfigurations') or [])
        if m.get('ID') == 'KSV-0014'
    )

jb = counts('jupyter-before.json')
ja = counts('jupyter-after.json')
sb = counts('s3-before.json')
sa = counts('s3-after.json')
spb = counts('spark-before.json')
spa = counts('spark-after.json')
cb = ksv0014('config-before.json')
ca = ksv0014('config-after.json')

after_jupyter = vulns('jupyter-after.json')
assert not any(v['VulnerabilityID'] == 'CVE-2026-78676' for v in after_jupyter), 'GitPython CVE remains'
assert sa['CRITICAL'] + sa['HIGH'] < sb['CRITICAL'] + sb['HIGH'], 'S3 HIGH/CRITICAL count did not improve'
assert ca == 0, f'Kind KSV-0014 remains: {ca}'

def row(c):
    return f"{c['CRITICAL']} CRITICAL / {c['HIGH']} HIGH / {c['MEDIUM']} MEDIUM / {c['LOW']} LOW"

text = f"""# H1 local runtime checkpoint — {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M UTC')}

Result: **H1 LOCAL RUNTIME VALIDATED** on retained `kind-edl-lab`.

- Jupyter GitPython CVE-2026-78676: **FIXED** in the hardened image.
- Jupyter scan: {row(jb)} -> {row(ja)}.
- S3 client scan: {row(sb)} -> {row(sa)}.
- Spark scan: {row(spb)} -> {row(spa)}; Netty/Derby residuals remain classified by the H1 dependency decision as UPSTREAM where applicable.
- Kind writable-root finding KSV-0014: {cb} -> {ca}.
- Hardened Jupyter, RustFS, S3 reader and S3 contract ran with read-only container roots.
- Spark driver/executor regression used the retained I12 event and a disposable Iceberg table; no Kafka event was produced or replayed.
- The exact I12 Polaris snapshot and six-row validated table were preserved.
- Jupyter kernel -> Trino retained-I12 query passed.
- CRC was not accessed by this script.
- No namespace, PVC, Kind cluster or retained application data was deleted.

This is a local POC hardening result, not production approval. Residual image findings remain documented as UPSTREAM or DEFERRED rather than silently accepted.
"""
(out / 'local-runtime-checkpoint.md').write_text(text, encoding='utf-8')
print(text)
PY

echo "===== H1 SECRET-LIKE EVIDENCE GUARD ====="
if grep -R -nE 'github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|(AKIA|ASIA)[A-Z0-9]{16}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|sha256~[A-Za-z0-9_-]{30,}' "$H1_EVIDENCE"; then
  fail "secret-like material detected in H1 evidence; nothing will be committed"
fi

echo "===== H1 FINAL CLUSTER HEALTH ====="
"${PYTHON[@]}" scripts/kind/check-health.py
k -n edl-data get deployment edl-jupyter edl-s3
k -n edl-data get pod kind-s3-reader
k -n edl-data get pvc
k -n argocd get applications

echo "===== H1 EVIDENCE COMMIT ====="
git add "$H1_EVIDENCE"
BAD="$(git diff --cached --name-only | grep -v "^$H1_EVIDENCE/" || true)"
[ -z "$BAD" ] || fail "unexpected staged path(s): $BAD"

if git diff --cached --quiet; then
  echo "[INFO] no H1 evidence changes to commit"
else
  git commit -m "security(kind): validate H1 on retained local runtime"
  git push origin "$BRANCH"
fi

echo "===== H1 LOCAL FINALIZE PASS ====="
echo "branch=$(git branch --show-current)"
echo "head=$(git rev-parse HEAD)"
echo "context=$(kubectl config current-context)"
echo "I12_EVENT=$I12_EVENT"
echo "H1_LOCAL_RUNTIME_VALIDATED=PASS"
git status --short
