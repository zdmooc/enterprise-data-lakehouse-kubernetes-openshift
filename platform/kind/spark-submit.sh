#!/usr/bin/env bash
set -euo pipefail
args=(
  --master k8s://https://kubernetes.default.svc:443 --deploy-mode cluster
  --name "kind-spark-$MODE"
  --conf spark.kubernetes.namespace=edl-data
  --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark-runner
  --conf spark.kubernetes.container.image=edl-spark-lakehouse:kind-4.1.3-iceberg1.11
  --conf spark.kubernetes.container.image.pullPolicy=IfNotPresent
  --conf "spark.kubernetes.driver.pod.name=kind-spark-$MODE-driver"
  --conf spark.kubernetes.driver.label.edl.network/api-client=true
  --conf spark.kubernetes.driver.podTemplateFile=/opt/edl-templates/pod.yaml
  --conf spark.kubernetes.executor.podTemplateFile=/opt/edl-templates/pod.yaml
  --conf spark.kubernetes.driver.podTemplateContainerName=spark-kubernetes
  --conf spark.kubernetes.executor.podTemplateContainerName=spark-kubernetes
  --conf spark.driver.port=7078 --conf spark.blockManager.port=7079
  --conf spark.eventLog.enabled=true
  --conf spark.eventLog.dir=file:/spark-events
  --conf spark.executor.instances=1
  --conf spark.driver.memory=1024m --conf spark.executor.memory=1024m
  --conf spark.driver.memoryOverhead=384m --conf spark.executor.memoryOverhead=384m
  --conf spark.kubernetes.driver.request.cores=200m
  --conf spark.kubernetes.executor.request.cores=200m
  --conf spark.kubernetes.driver.limit.cores=1
  --conf spark.kubernetes.executor.limit.cores=1
)
if [ "$MODE" = smoke ]; then
  args+=(local:///opt/spark/examples/src/main/python/pi.py 10)
elif [ "$MODE" = lakehouse ]; then
  args+=(
    --conf spark.kubernetes.driver.secretKeyRef.POLARIS_CREDENTIAL=polaris-client:POLARIS_CREDENTIAL
    --conf spark.kubernetes.driverEnv.KAFKA_BOOTSTRAP=edl-kafka-kafka-bootstrap.edl-data.svc.cluster.local:9092
    --conf spark.kubernetes.driverEnv.KAFKA_TOPIC=transactions.raw
    --conf spark.kubernetes.driverEnv.POLARIS_URI=http://edl-polaris.edl-data.svc.cluster.local:8181/api/catalog
    --conf spark.kubernetes.driverEnv.POLARIS_WAREHOUSE=quickstart_catalog
  )
  for role in driver executor; do
    args+=(
      --conf "spark.kubernetes.$role.secretKeyRef.AWS_ACCESS_KEY_ID=kind-s3:AWS_ACCESS_KEY_ID"
      --conf "spark.kubernetes.$role.secretKeyRef.AWS_SECRET_ACCESS_KEY=kind-s3:AWS_SECRET_ACCESS_KEY"
      --conf "spark.kubernetes.$role.secretKeyRef.AWS_REGION=kind-s3:AWS_DEFAULT_REGION"
      --conf "spark.kubernetes.$role.secretKeyRef.S3_ENDPOINT=kind-s3:S3_ENDPOINT"
    )
  done
  args+=(local:///opt/spark/work-dir/jobs/transactions_to_iceberg.py)
else
  echo 'Invalid Spark MODE' >&2; exit 1
fi
exec /opt/spark/bin/spark-submit "${args[@]}"
