# Logging Strategy

## Principle

Applications write structured operational logs to stdout/stderr.

The platform does **not** install a second logging stack blindly on CRC.

## OpenShift target

Preferred order:

1. reuse the cluster-supported OpenShift logging capability when available;
2. route/retain logs through the supported Loki/OpenShift Logging path;
3. use OpenSearch/ELK when a concrete requirement justifies it.

## Required fields for Data Product logs

- timestamp;
- component;
- namespace;
- pod;
- correlation / run ID;
- topic where relevant;
- Spark application ID where relevant;
- Trino query ID where relevant;
- severity;
- error category.

Never log:
- passwords;
- tokens;
- S3 secret keys;
- personal/customer data in this synthetic public lab.

## Specialist reuse

Deep ELK/OpenSearch patterns remain in:

`zdmooc/elk-log-data-platform`

I10 focuses on correlation and operability rather than duplicating that repository.
