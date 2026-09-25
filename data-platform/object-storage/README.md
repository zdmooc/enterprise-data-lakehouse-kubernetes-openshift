# I4 — Object Storage / S3 Contract

The platform consumes an **S3-compatible capability**, not a hard-coded MinIO implementation.

See ADR-002.

## Required runtime variables

Do not commit real credentials.

Example local environment:

```bash
export S3_ENDPOINT="https://object-storage.example"
export S3_BUCKET="edl-lab"
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_DEFAULT_REGION="us-east-1"
```

## Contract

The provider must support:
- bucket access;
- PUT/GET/DELETE;
- objects large enough for Data files;
- TLS;
- credentials or workload identity;
- persistent storage;
- observable errors and capacity.

## Validate

With AWS CLI installed:

```bash
bash scripts/s3-contract-check.sh
```

The test writes a synthetic object, verifies byte-for-byte integrity, and deletes it.

## Provider overlays

Planned:
- `providers/aistor/`
- optional lightweight maintained S3 lab provider if licensing blocks AIStor
- `providers/legacy-minio-oss/` only if explicitly needed for historical compatibility testing

No provider is marked runtime validated yet.
