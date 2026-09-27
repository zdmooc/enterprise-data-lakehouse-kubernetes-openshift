"""Redacted, pattern-based scan of blobs reachable from local Git refs.

This catches common credential formats; it is not an exhaustive secret detector.
No token value is printed. Fetch complete history before invoking in CI.
"""
import subprocess, re, json
from pathlib import Path
def git(*args):
    return subprocess.check_output(['git',*args])
entries = git('rev-list','--objects','--all').decode().splitlines()
paths = dict(line.split(' ',1) for line in entries if ' ' in line)
ids = list(paths)
proc = subprocess.Popen(['git','cat-file','--batch'],stdin=subprocess.PIPE,stdout=subprocess.PIPE)
# communicate avoids deadlock when the history exceeds a pipe buffer.
data,_ = proc.communicate(('\n'.join(ids)+'\n').encode())
offset=0
findings=[]
blobs=0
rules={
 'private-key':rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
 'github-token':rb'(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})',
 'aws-access-key':rb'(?:AKIA|ASIA)[A-Z0-9]{16}',
 'jwt':rb'eyJ[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{15,}',
 'openshift-token':rb'sha256~[A-Za-z0-9_-]{35,}',
 'literal-secret':rb'(?im)^\s*(?:client_secret|clientSecret|password|access_token|refresh_token|AWS_SECRET_ACCESS_KEY)\s*[:=]\s*["\x27]?([A-Za-z0-9_+/=-]{16,})',
}
for oid in ids:
    end=data.index(b'\n',offset)
    header=data[offset:end].split()
    size=int(header[2]); content=data[end+1:end+1+size];offset=end+size+2
    if header[1]!=b'blob':continue
    blobs+=1
    for label,pattern in rules.items():
        for match in re.finditer(pattern,content):
            findings.append({'blob':oid,'path':paths[oid],'line':content[:match.start()].count(b'\n')+1,'rule':label})
result={'commits':int(git('rev-list','--count','--all')),'blobs':blobs,'findings':findings,'limitation':'Pattern-based scan, not proof of secret absence; other repositories are outside scope.'}
Path('.audit').mkdir(exist_ok=True)
Path('.audit/history-secret-scan.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result,indent=2))
raise SystemExit(bool(findings))
