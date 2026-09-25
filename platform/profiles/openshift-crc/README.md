# Platform Profile — OpenShift Local / CRC

## Purpose

Use CRC for OpenShift-specific validation:
- Projects;
- Routes;
- SCC;
- Operators;
- OpenShift GitOps;
- Strimzi;
- RBAC;
- NetworkPolicies;
- lightweight Data workloads.

## Limitations

CRC single-node is not evidence for:
- HA;
- worker failure resilience;
- multi-node Kafka behavior;
- production storage;
- production throughput.

## Rule

Heavy Data services are deployed progressively and may be mutually exclusive in local profiles to stay within workstation resources.
