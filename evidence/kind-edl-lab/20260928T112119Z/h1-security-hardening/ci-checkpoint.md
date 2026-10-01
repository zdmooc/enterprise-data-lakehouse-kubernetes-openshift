# H1 GitHub CI checkpoint — 2026-09-30

This checkpoint records GitHub-hosted CI evidence only. It does not replace the
required local `kind-edl-lab` regression against the retained I12 snapshot/PVCs.

## Proven in CI

- Kind hardening manifest contracts: PASS.
- Secret hygiene regression: PASS.
- Spark 4.1.3 local-mode execution with a read-only root filesystem: PASS.
- Jupyter derivative build with GitPython 3.1.59: PASS.
- Jupyter read-only container smoke: PASS.
- GitPython CVE-2026-78676 absent after scan: PASS.
- Jupyter Trivy occurrence counts changed from 8 CRITICAL / 205 HIGH /
  3926 MEDIUM / 316 LOW to 7 CRITICAL / 198 HIGH / 3923 MEDIUM / 316 LOW.
- RustFS + S3 PUT/GET/integrity/DELETE and logical-zone contract under
  read-only root filesystems: PASS.
- AWS CLI 2.31.0 S3 baseline: 213 HIGH / 134 MEDIUM / 10 LOW.
- AWS CLI 2.37.5 candidate: 14 HIGH / 7 MEDIUM.
- The 2.37.5 candidate passed the same read-only S3 contract and was selected
  for the H1 client image.

## Still local-only

The following remain NOT YET PROVEN by GitHub Actions:

- deployment of the hardened images into the retained `kind-edl-lab`;
- Jupyter kernel -> Trino read of the retained I12 transaction;
- Spark executor/driver regression against Kafka/Iceberg/Polaris in the local lab;
- local Trivy after scans using the workstation's frozen H1 database;
- Kind -> CRC -> Kind switching.

No GitHub CI result is presented as production approval or as proof of multi-host HA.
