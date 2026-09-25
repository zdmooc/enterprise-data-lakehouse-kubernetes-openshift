# Runbook — PVC / S3 Storage Failure

## First split the problem

### Kubernetes persistent volume

```bash
oc -n edl-data get pvc,pod
oc -n edl-data describe pvc <pvc>
oc get storageclass
oc -n edl-data get events --sort-by=.lastTimestamp | tail -50
```

Check:
- PVC Pending;
- access mode;
- quota;
- StorageClass;
- node/volume attachment;
- filesystem permissions;
- capacity.

### S3-compatible object storage

```bash
bash scripts/s3-contract-check.sh
```

Check:
- endpoint/DNS;
- TLS;
- credentials/identity;
- bucket existence;
- PUT/GET;
- capacity;
- network path.

## Rule

PVC success does not prove S3 success, and S3 success does not prove Iceberg catalog correctness.
