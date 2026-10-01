#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
inventory
guard
# Run only after the real end-to-end and recovery gates have passed.
grep -Fq '[PASS] Kafka -> Spark -> Iceberg/S3 -> Polaris -> Trino -> Jupyter' "$EVIDENCE_DIR/19-e2e-output.txt" || fail 'E2E gate required first'
grep -Fq '[PASS] KIND_MULTI_NODE_FUNCTIONAL_RECOVERY' "$EVIDENCE_DIR/i11-recovery.txt" || fail 'recovery gate required first'
exec > >(tee "$EVIDENCE_DIR/crc-kind-switch.txt") 2>&1
bash scripts/kind/stop-edl-lab.sh
# CRC startup can print credentials. Keep its complete output in ignored local storage.
umask 077
crc_ok=true
if crc start > .audit/kind/crc-start-private.log 2>&1; then
  if kubectl config use-context crc-admin && crc status && kubectl --context=crc-admin get nodes -o wide; then
    echo '[PASS] CRC started and its nodes were readable'
  else
    crc_ok=false
    echo '[FAIL] CRC read-only inspection failed; restoring Kind next'
  fi
  echo '[INFO] CRC API inspection was read-only; no CRC workload changes requested'
else
  crc_ok=false
  echo '[FAIL] CRC startup failed; details retained in ignored private log'
fi
crc stop
bash scripts/kind/start-edl-lab.sh
# Preserve the pre-switch proof before a fresh end-to-end run.
cp "$EVIDENCE_DIR/19-e2e-output.txt" "$EVIDENCE_DIR/e2e-before-switch.txt"
bash scripts/e2e-lakehouse-kind.sh
[ "$crc_ok" = true ] || fail 'Kind restored, but CRC switching gate failed'
echo '[PASS] Kind -> CRC read-only inspection -> Kind, followed by fresh E2E'
