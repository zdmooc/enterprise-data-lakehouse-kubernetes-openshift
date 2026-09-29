# Security findings and scope

Scanner: Trivy 0.74.0. Raw JSON stays in ignored `.audit/kind/` because secret
scanner output can include sensitive snippets. The versionable summary prints only
finding identifiers, package versions, severity and target names. Counts below are
finding occurrences, not unique CVEs or proof of exploitability.

Image scan coverage is the three locally built images: Spark, Jupyter and the S3
contract client. Vulnerability scans of other upstream images (RustFS service,
Kafka, Polaris, Trino, cluster and monitoring components) are `NOT_TESTED` in this
pack. Their deployment/readiness tests do not substitute for vulnerability scanning.

## Repository configuration scan

The completed repository scan found no secrets. It reported 28 HIGH, 25 MEDIUM and
249 LOW configuration findings across the repository, including existing profiles
and deliberate negative-test fixtures. Six Kind manifests have the HIGH KSV-0014
finding: writable container root filesystems (Jupyter, RustFS and four probe/job
manifests). Restricted PSS, non-root execution and dropped capabilities do not remove
this finding. A read-only root filesystem with explicit writable mounts remains a
hardening task; this run does not claim that control is enforced.

## Spark image

The scanned image is the digest recorded in `spark-image.txt`. Trivy reported
10 CRITICAL, 276 HIGH, 3567 MEDIUM and 336 LOW occurrences.

Critical findings include:

| Package | Installed | Finding | Scanner-provided fixed version |
| --- | --- | --- | --- |
| io.netty:netty-handler | 4.2.13.Final and embedded 4.2.7.Final copies | CVE-2026-75595 | 4.2.17.Final or 4.1.137.Final |
| org.apache.derby:derby | 10.16.1.1 | CVE-2022-46337 | 10.16.1.2 on this version line |
| linux-libc-dev | 5.15.0-194.204 | Six critical occurrences, listed in the sanitized scan | No fixed version supplied |

Replacing embedded Spark/Iceberg dependencies requires a separately tested compatible
image update. No arbitrary jar replacement was performed during runtime validation.
The `linux-libc-dev` package findings do not establish the running host kernel's
vulnerability status. Scanner results alone do not establish exploitability.

## Jupyter and S3 client images

| Image | CRITICAL | HIGH | MEDIUM | LOW |
| --- | ---: | ---: | ---: | ---: |
| Jupyter (digest in jupyter-image.txt) | 7 | 198 | 3916 | 306 |
| S3 contract client | 0 | 199 | 127 | 10 |

Jupyter's critical occurrences include six `linux-libc-dev` findings and
CVE-2026-78676 in GitPython 3.1.57 (scanner-provided fix: 3.1.59). The S3 client
includes an older Amazon Linux/AWS CLI base with fixable package findings. The
client is a diagnostic workload, but that does not make the findings disappear.
All HIGH/CRITICAL package occurrences and available fixes are in `i9-supply-chain.txt`.
Image dependency remediation and rebuilt-image regression tests remain separate
hardening work; these images were not certified vulnerability-free.

## Interpretation

Admission/RBAC/NetworkPolicy runtime proofs and completed vulnerability scans are
distinct from a clean security posture. Any `RUNTIME_VALIDATED` security gate in the
summary refers to executed controls and scans, not zero findings. This single-laptop
lab is not approved for production use by these results.
