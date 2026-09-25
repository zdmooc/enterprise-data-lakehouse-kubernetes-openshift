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

`s3://$S3_BUCKET`

## Important limitation

The CRC profile deliberately uses in-memory metadata. Restarting Polaris loses catalog metadata.

That is acceptable only for a disposable integration lab.

Production architecture uses persistent metadata, preferably PostgreSQL for this reference architecture.
