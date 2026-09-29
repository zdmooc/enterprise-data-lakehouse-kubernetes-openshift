#!/usr/bin/env bash
source "$(dirname "$0")/kind/common.sh"
inventory
guard
ready_nodes
for deployment in $(k -n edl-data get deployment -o name); do
  k -n edl-data rollout status "$deployment" --timeout=180s
done
k -n edl-data wait --for=condition=Ready kafka/edl-kafka --timeout=180s
marker="kind-e2e-$(date -u +%s)-$$"
payload="{\"eventId\":\"$marker\",\"eventTime\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"transactionId\":\"$marker\",\"amount\":17.42,\"currency\":\"EUR\",\"status\":\"ACCEPTED\",\"channel\":\"E2E\",\"country\":\"FR\",\"latencyMs\":7}"
exec > >(tee "$EVIDENCE_DIR/19-e2e-output.txt") 2>&1
echo "E2E_EVENT_ID=$marker"
k -n edl-data exec kind-kafka-client -- bash -ec "printf '%s\n' '$payload' | /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server edl-kafka-kafka-bootstrap:9092 --topic transactions.raw"
echo '[PASS] fresh transaction published to Kafka'
bash scripts/kind/spark.sh lakehouse
coordinator="$(k -n edl-data get pod -l app.kubernetes.io/component=coordinator -o jsonpath='{.items[0].metadata.name}')"
rows="$(k -n edl-data exec "$coordinator" -- trino --server http://localhost:8080 --user edl --output-format TSV --execute "SELECT eventId FROM polaris.analytics.transactions WHERE eventId='$marker'")"
[ "$rows" = "$marker" ] || fail 'Trino did not return the fresh E2E event'
echo '[PASS] Trino read the exact fresh Kafka event from Iceberg'
k -n edl-data exec deployment/edl-jupyter -- python -c 'import os,sys,trino; c=trino.dbapi.connect(host=os.environ["TRINO_HOST"],port=8080,user="data-analyst",catalog="polaris",schema="analytics"); cur=c.cursor(); cur.execute("SELECT eventId, amount, channel FROM transactions WHERE eventId = ?",[sys.argv[1]]); rows=cur.fetchall(); assert len(rows)==1 and rows[0][0]==sys.argv[1] and rows[0][2]=="E2E", rows; print("[PASS] Jupyter read the same fresh event:",rows)' "$marker"
guard
k apply -f platform/kind/s3-reader.yaml
k -n edl-data wait --for=condition=Ready pod/kind-s3-reader --timeout=120s
objects="$(k -n edl-data exec kind-s3-reader -- bash -ec 'aws --endpoint-url "$S3_ENDPOINT" s3 ls "s3://$S3_BUCKET/curated/" --recursive')"
printf '%s\n' "$objects"
printf '%s\n' "$objects" | grep -q '\.parquet$' || fail 'no Iceberg data files in S3'
printf '%s\n' "$objects" | grep -q '\.metadata.json$' || fail 'no Iceberg metadata files in S3'
echo '[PASS] Kafka -> Spark -> Iceberg/S3 -> Polaris -> Trino -> Jupyter'
resource_check | tee -a "$EVIDENCE_DIR/20-resource-usage.txt"
