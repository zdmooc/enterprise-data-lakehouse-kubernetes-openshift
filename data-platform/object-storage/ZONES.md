# Object Storage Data Zones

I4 uses an S3-compatible contract. The logical layout is provider-neutral.

## Required prefixes

```text
s3://<bucket>/
├── raw/
├── curated/
├── checkpoints/
└── evidence/
```

- `raw/`: immutable or append-oriented landing data.
- `curated/`: validated/transformed Data Product outputs.
- `checkpoints/`: processing checkpoints when a workload requires them.
- `evidence/`: synthetic lab evidence only; never secrets.

Iceberg table data may use its own catalog-managed prefix under the same lab bucket or a dedicated production bucket.

## Production projection

Production may split the zones into separate buckets/accounts/policies. The lab layout is not a production mandate.
