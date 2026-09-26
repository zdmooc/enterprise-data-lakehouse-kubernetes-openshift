# Data Product Network Flows

The I2 baseline is deny-by-default for ingress and egress.

This directory adds only the flows needed by the Data Product.

## Allowed flows

- Kafka pods -> same namespace, for broker/controller internal communication.
- Spark driver -> Kafka 9092.
- Spark driver -> Polaris 8181.
- Spark submit/driver -> Kubernetes/OpenShift API over 443.
- Trino -> Trino 8080.
- Trino -> Polaris 8181.
- Jupyter -> Trino 8080.
- Polaris/Trino/Spark -> HTTPS object storage where the S3 endpoint is external.
- Polaris -> in-namespace S3 lab endpoint on 9000 when used.

## Security note

The HTTPS `0.0.0.0/0:443` rules are a CRC/lab portability compromise because the API/S3 endpoint CIDRs are environment-specific.

A production profile must replace them with approved API, proxy and object-storage CIDRs or egress gateway policy.

No policy here opens ingress from another POC namespace.
