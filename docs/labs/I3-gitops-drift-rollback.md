# I3 Lab — Drift, Reconciliation and Rollback

## Safety

This lab must be executed only after I1/I2 runtime validation.

It does not require deleting existing Payment, TradeOps, MQ or other namespaces.

Target scope is limited to the Enterprise Data Lakehouse namespaces and Argo CD resources.

## Step 1 — Status

```bash
bash scripts/gitops-status.sh
```

Expected:
- AppProject exists;
- `edl-platform-baseline` is Synced;
- health is Healthy or an explicitly understood transitional state.

## Step 2 — Controlled drift

Choose one harmless field owned by Git in the EDL baseline, for example a quota value in `edl-data`.

Record the current value first.

Then patch only the EDL resource.

Do not modify any other POC namespace.

Observe:

```bash
oc -n openshift-gitops get application edl-platform-baseline -w
```

Expected:
- drift becomes visible;
- self-heal restores Git state.

## Step 3 — Git reconciliation

Change one lab-safe declarative value in Git, for example a non-disruptive label or quota value.

Commit/push.

Observe Argo CD reconciliation.

Capture:
- Git commit SHA;
- Application revision;
- before/after value.

## Step 4 — Rollback

Revert the Git commit.

Observe Argo CD returning the resource to the previous state.

Rollback proof is a Git revert + reconciliation, not a manual imperative repair.

## Evidence

Store evidence under:

`evidence/runtime/I3-<date>-gitops-drift-rollback.md`

Required fields:
- target cluster/profile;
- commands;
- before state;
- drift state;
- healed state;
- Git commit;
- revert commit;
- final Application sync/health;
- limitations.

## Truth boundary

Passing this lab proves GitOps reconciliation on the tested cluster only.

It does not prove:
- multi-cluster GitOps;
- production change governance;
- disaster recovery;
- HA of Argo CD.
