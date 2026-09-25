# Platform Profile — Kubernetes The Hard Way

This profile consumes a Kubernetes cluster built by the existing KTHW repositories.

## Expected contract

The target cluster must provide:
- functional API server;
- healthy etcd;
- schedulable workers;
- working DNS;
- working CNI;
- default StorageClass or documented manual storage path;
- ingress capability;
- cluster-admin bootstrap access for platform installation.

## Source repositories

- `zdmooc/kubernetes-the-hard-way-vagrant-architect-v29`
- `zdmooc/kubernetes-the-hard-way-multicloud`

This repository does not reproduce the KTHW bootstrap.
