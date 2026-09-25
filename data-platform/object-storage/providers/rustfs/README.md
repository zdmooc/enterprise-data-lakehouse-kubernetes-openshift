# RustFS — Optional S3-compatible Lab Provider

RustFS is a maintained Apache-2.0 S3-compatible object store and is a possible provider behind the I4 S3 contract.

## Why it is evaluated

The historical MinIO OSS server/operator line is archived. MinIO AIStor remains a valid supported product when its licensing and compatibility fit the environment.

RustFS provides an open-source alternative for lab portability.

## OpenShift caution

The RustFS Operator upstream repository includes an OpenShift tenant example for `restricted-v2`, but the example explicitly requires an arbitrary-UID-compatible RustFS image.

Therefore this repository does **not** claim a ready OpenShift RustFS deployment until:
- a compatible image is selected or built;
- SCC admission succeeds;
- PVC permissions work;
- S3 PUT/GET/DELETE is runtime validated.

## Architecture rule

Data workloads depend on the S3 contract, not on RustFS-specific APIs.

Other providers can replace RustFS without changing Spark/Iceberg/Trino business logic.
