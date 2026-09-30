# H1 dependency decisions

Baseline: `377704b8f95b02f8a5c6820cb580abdf28d31e34`, `runtime/kind-edl-lab`.
Context checked before changes: `kind-edl-lab`. Only Kind profiles are in scope.

## Jupyter

The acquired image contains GitPython 3.1.57. The Kind derivative pins 3.1.59,
the scanner's fixed version for CVE-2026-78676. Upstream documents the security
fixes in the [GitPython changelog](https://gitpython.readthedocs.io/en/latest/changes.html).
This targeted upgrade does not imply all Jupyter dependencies are fixed.
The root filesystem is read-only; ephemeral home/cache and `/tmp` have explicit
emptyDir volumes, while `/home/jovyan/work` retains the original PVC.

## Spark / Netty

CVE-2026-75595 occurs in three distinct locations in the acquired image:

| Owner | Path under `/opt/spark/jars` | Embedded Netty |
|---|---|---|
| Spark transport | `netty-handler-4.2.7.Final.jar` | 4.2.7.Final |
| Spark Connect | `connect-repl/spark-connect-client-jvm_2.13-4.1.3.jar` | 4.2.7.Final |
| Iceberg AWS bundle | `iceberg-aws-bundle-1.11.0.jar` | 4.2.13.Final |

The [Netty advisory](https://github.com/netty/netty/security/advisories/GHSA-c4c3-7fpv-j4q5)
identifies a fragmented ClientHello/SNI fallback problem; patched branches start
at 4.2.17.Final / 4.1.137.Final. This lab does not use SNI as an mTLS authorization
gate, but vulnerable packages remain findings: no blanket NOT_APPLICABLE claim.

The official Spark 4.1.3 parent POM pins Netty 4.2.7.Final. Even the published
Spark 4.2.0 parent pins 4.2.13.Final (see `spark-upstream.txt`). A Spark major/minor
upgrade alone would not resolve this CVE. No individual Netty JAR is substituted,
no shaded bundle is edited, and no vulnerable JAR is removed to hide a finding.

An official Iceberg runtime/AWS bundle upgrade is evaluated as a matched pair for
Spark 4.1 / Scala 2.13. [Iceberg 1.12.0 release](https://github.com/apache/iceberg/releases/tag/apache-iceberg-1.12.0).
Final adoption and remaining copies are established by the build, regression and
after scan, not by the release number alone.

## Spark / Derby

The acquired `derby-10.16.1.1.jar` is reported for CVE-2022-46337. The scanner names
10.16.1.2, but that version is absent from Maven Central's published Derby metadata
at this checkpoint (see `upstream-versions.json`). Spark 4.1.3 and 4.2.0 both pin
10.16.1.1. This POC uses Polaris REST, not Derby LDAP authentication. Keep the
finding UPSTREAM rather than substitute an unverified or unrelated Derby JAR.

## S3 contract client

The original Kind client is based on `amazon/aws-cli:2.31.0`. A package-only
`yum update` derivative did not reduce Trivy findings with the 2026-09-30 CI
database: 213 HIGH / 134 MEDIUM remained unchanged.

A pinned `amazon/aws-cli:2.37.5` candidate was therefore tested before adoption.
On the same GitHub Actions run and Trivy database it reported 14 HIGH / 7 MEDIUM,
while both the read-only container smoke and the full RustFS S3
PUT/GET/integrity/DELETE + zone-layout contract passed. The H1 image now pins
2.37.5; this is a reduction, not a claim of zero vulnerabilities. Remaining
findings stay DEFERRED unless separately classified.

## Scope and classification

FIXED means an identified finding is absent from the final scan of that component.
UPSTREAM means the shipped dependency is retained pending a compatible upstream
distribution. DEFERRED means a remaining finding has not been remediated in this
targeted checkpoint; it is not a safety approval. ACCEPTED_RISK is not assigned
without an explicit risk acceptance. NOT_APPLICABLE is not used merely because
an exploit path has not been demonstrated.

Kafka, Polaris, Trino, Prometheus, Grafana and cluster component images are not
modified or rescanned: NOT_TESTED for H1 vulnerability scanning. RustFS and the
BusyBox probe are configuration-only checks, also NOT_TESTED for image CVEs.
Raw scanner JSON stays under ignored `.audit/kind/h1/`. Published scans contain
finding identifiers/package metadata only, never secret matches or snippets.
