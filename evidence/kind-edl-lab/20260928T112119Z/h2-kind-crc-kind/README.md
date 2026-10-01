# H2 — Kind -> CRC -> Kind local switch

Result: **KIND_CRC_KIND_LOCAL_SWITCH_VALIDATED**

- Start state: retained , 3 Ready nodes.
- H1 prerequisite: locally validated and pushed before H2.
- Kind stop/start used the existing three Docker node containers; no Kind delete/recreate.
- CRC was started and inspected read-only; H2 issued no CRC workload mutation.
- CRC was stopped before the existing Kind containers were restarted.
- Final Kind state passed the repository health gate.
- Exactly six retained Iceberg transactions were verified.
- Retained I12 event: .
- Jupyter persistent marker and Jupyter -> Trino -> I12 passed after the switch.
- S3 metadata retained the exact I12 snapshot/table UUID.
- Polaris is an in-memory lab catalog. If it was empty after process restart, H2 used metadata-only registration of the already-existing I12 Iceberg metadata file. It did not replay Kafka, rerun the batch transform, or rewrite S3/Iceberg data.
- No namespace, PVC, cluster or retained application data was deleted.

This validates local operational switching on one workstation. It is not multi-host HA, DR, durable-catalog or production approval.
