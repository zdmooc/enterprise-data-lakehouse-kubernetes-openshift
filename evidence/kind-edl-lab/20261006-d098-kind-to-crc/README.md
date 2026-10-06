# D-098 — Kind -> CRC helper runtime validation — 2026-10-06

**Result:** `D098_KIND_TO_CRC_HELPER=RUNTIME_VALIDATED`

## Scope

This validates the D-098 convenience path that leaves CRC/OpenShift Local active for the SQY runtime evidence work.

It does **not** replace the canonical H2 proof `KIND_CRC_KIND_LOCAL_SWITCH_VALIDATED`; H2 remains the end-to-end Kind -> CRC -> Kind retention proof.

## Observed sequence

Start state:
- branch `runtime/kind-edl-lab`;
- retained Kind cluster `edl-lab`;
- 3 Kind nodes Ready;
- Kubernetes v1.33.1;
- node IPs preserved:
  - control-plane: 172.18.0.2
  - worker2: 172.18.0.3
  - worker: 172.18.0.4
- CRC stopped.

CRC configuration before the successful run:
- CPU: 8;
- memory: 16384 MiB;
- disk-size: 200 GiB;
- cluster monitoring enabled.

The helper:
1. verified the retained Kind cluster;
2. stopped local demo port-forwards;
3. stopped the three existing Kind node containers without deleting the cluster;
4. started CRC;
5. selected/recovered the OpenShift admin context;
6. waited for the CRC node to be Ready;
7. left CRC active for subsequent SQY evidence.

## Observed OpenShift state

- CRC VM: Running;
- OpenShift: Running 4.22.7;
- current context: `crc-admin`;
- authenticated user: `kubeadmin`;
- API: `https://api.crc.testing:6443`;
- ClusterVersion 4.22.7 Available=True, Progressing=False;
- listed ClusterOperators Available=True, Progressing=False, Degraded=False;
- node `crc`: Ready;
- Kubernetes version: v1.35.6;
- node roles: control-plane, master, worker;
- container runtime: CRI-O 1.35.5.

Final marker observed:

```text
[PASS] Kind retained/stopped; CRC/OpenShift active
```

## Previous failure and correction

The first D-098 helper attempt exposed two local conditions:
- CRC had been configured with 32768 MiB and Hyper-V could not allocate enough host memory;
- after lowering CRC to 16384 MiB, a transient OAuth reset prevented `crc start` from adding `crc-admin`.

The helper was hardened in commit:
`207431599b5c23845187a4f4af08e9ca78cbd285`.

The successful runtime validation is the first run after that hardening.

## Truth boundary

This proves:
- safe local transition from retained Kind to active CRC/OpenShift;
- no Kind delete/recreate;
- OpenShift control plane/operator readiness sufficient to begin SQY read-only evidence.

It does not prove:
- CRC -> Kind return for this specific run yet;
- OpenShift HA;
- multi-node OpenShift;
- production readiness.

Return validation remains:
`CONFIRM_DEMO_SWITCH=yes bash demo/scripts/01-switch-crc-to-kind.sh`,
followed by the retained Lakehouse preflight.
