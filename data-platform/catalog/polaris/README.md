# I12 Catalog — Apache Polaris

## Baseline

- Apache Polaris: **1.7.0**
- official Helm repository: `https://downloads.apache.org/polaris/helm-chart`
- protocol: Apache Iceberg REST Catalog
- CRC persistence: `in-memory` — development only

Polaris' Helm chart requires Kubernetes 1.33+.

## Install on CRC

Required environment:

```bash
export S3_ENDPOINT="https://s3-endpoint-reachable-by-data-workloads"
export S3_ENDPOINT_INTERNAL="$S3_ENDPOINT"
export S3_BUCKET="edl-lakehouse"
export S3_REGION="us-east-1"
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
```

Then:

```bash
bash scripts/install-polaris-crc.sh
bash scripts/bootstrap-polaris-catalog.sh
```

The scripts generate the Polaris client secret at runtime.

## Catalog

Name:

`quickstart_catalog`

Default base location:

`s3://$S3_BUCKET/curated/`

## CRC storage contract

This profile uses `stsUnavailable: true` for an S3-compatible provider without
STS. Credential vending is disabled. Polaris, Spark driver/executor and Trino
receive the dedicated bucket credentials through Secret references. Both
`S3_ENDPOINT` (clients) and `S3_ENDPOINT_INTERNAL` (Polaris) must be reachable
from the corresponding pods over HTTPS/443 with a trusted certificate.
An HTTP/9000 provider needs a reviewed destination-specific network overlay;
the existing driver/executor/Trino profile does not allow that path.

Use credentials restricted to the disposable EDL bucket. The CRC profile shares
the bootstrap root Polaris identity; separate least-privilege catalog identities
and persistent metadata remain enterprise design work. Reinstall reuses the
client secret. Secret rotation and consumer restart require a dedicated procedure.
An existing catalog with a different storage contract causes bootstrap to stop;
review its migration rather than deleting its metadata.

## Important limitation

The CRC profile deliberately uses in-memory metadata. Restarting Polaris loses catalog metadata.

That is acceptable only for a disposable integration lab.

Production architecture uses persistent metadata, preferably PostgreSQL for this reference architecture.
