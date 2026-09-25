# I8 — Jupyter / Data User Experience

## Goal

Give a Data analyst a controlled notebook environment that can query Trino without granting cluster-admin access.

## Image

Base image:

`quay.io/jupyter/scipy-notebook:2026-07-28`

Derived image adds:
- Trino Python client 0.340.0;
- OpenShift arbitrary-UID-oriented permissions;
- sample Trino query.

The image is built inside OpenShift using a BuildConfig and stored in the integrated image registry.

## Deploy on CRC

```bash
bash scripts/deploy-jupyter-crc.sh
```

The script:
1. generates a random Jupyter token locally;
2. stores it in a Kubernetes Secret;
3. creates the ImageStream/BuildConfig;
4. builds the image;
5. deploys Jupyter;
6. prints the HTTPS Route.

No token is committed to Git.

## Workspace

A 1 GiB PVC is mounted at:

`/home/jovyan/work`

Runtime validation must prove that the OpenShift-assigned UID can write to the PVC and that files survive pod recreation.

## Trino sample

Inside the notebook terminal:

```bash
python /home/jovyan/work/trino_query.py
```

## Security boundary

This is a single-user lab profile.

A production Data Science platform would additionally require:
- enterprise identity/OIDC;
- per-user workspace isolation;
- quotas;
- image governance;
- controlled package installation;
- audit;
- lifecycle and idle culling.

Those concerns are addressed later in I9/I10 and are not claimed solved by this CRC profile.
