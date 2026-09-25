import json
import os
from kafka import KafkaConsumer
from pyspark.sql import SparkSession, functions as F, types as T

bootstrap = os.getenv("KAFKA_BOOTSTRAP", "edl-kafka-kafka-bootstrap.edl-data.svc:9092")
topic = os.getenv("KAFKA_TOPIC", "transactions.raw")
polaris_uri = os.getenv("POLARIS_URI", "http://edl-polaris.edl-data.svc:8181/api/catalog")
polaris_warehouse = os.getenv("POLARIS_WAREHOUSE", "quickstart_catalog")
polaris_credential = os.environ["POLARIS_CREDENTIAL"]

spark = (
    SparkSession.builder.appName("edl-transactions-to-iceberg")
    .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
    .config("spark.sql.catalog.polaris", "org.apache.iceberg.spark.SparkCatalog")
    .config("spark.sql.catalog.polaris.type", "rest")
    .config("spark.sql.catalog.polaris.uri", polaris_uri)
    .config("spark.sql.catalog.polaris.warehouse", polaris_warehouse)
    .config("spark.sql.catalog.polaris.scope", "PRINCIPAL_ROLE:ALL")
    .config("spark.sql.catalog.polaris.credential", polaris_credential)
    .config("spark.sql.catalog.polaris.token-refresh-enabled", "false")
    .config("spark.sql.catalog.polaris.header.X-Iceberg-Access-Delegation", "vended-credentials")
    .config("spark.sql.catalog.polaris.io-impl", "org.apache.iceberg.io.ResolvingFileIO")
    .getOrCreate()
)

consumer = KafkaConsumer(
    topic,
    bootstrap_servers=bootstrap,
    auto_offset_reset="earliest",
    enable_auto_commit=False,
    group_id=f"edl-spark-{os.getpid()}",
    consumer_timeout_ms=10000,
    value_deserializer=lambda v: json.loads(v.decode("utf-8")),
)

rows = [record.value for record in consumer]
consumer.close()

if not rows:
    raise RuntimeError(f"No events read from Kafka topic {topic}")

schema = T.StructType(
    [
        T.StructField("eventId", T.StringType(), False),
        T.StructField("eventTime", T.StringType(), False),
        T.StructField("transactionId", T.StringType(), False),
        T.StructField("amount", T.DoubleType(), False),
        T.StructField("currency", T.StringType(), False),
        T.StructField("status", T.StringType(), False),
        T.StructField("channel", T.StringType(), False),
        T.StructField("country", T.StringType(), False),
        T.StructField("latencyMs", T.IntegerType(), False),
    ]
)

df = spark.createDataFrame(rows, schema)

curated = (
    df.withColumn("eventTime", F.to_timestamp("eventTime"))
    .withColumn("amount", F.round("amount", 2))
    .withColumn(
        "latencyBucket",
        F.when(F.col("latencyMs") < 100, "FAST")
        .when(F.col("latencyMs") < 250, "NORMAL")
        .otherwise("SLOW"),
    )
)

spark.sql("CREATE NAMESPACE IF NOT EXISTS polaris.analytics")

(
    curated.writeTo("polaris.analytics.transactions")
    .using("iceberg")
    .createOrReplace()
)

print("=== EDL_ICEBERG_TABLE ===")
spark.sql(
    """
    SELECT status, channel,
           count(*) AS transactionCount,
           round(sum(amount), 2) AS totalAmount,
           round(avg(latencyMs), 2) AS avgLatencyMs
    FROM polaris.analytics.transactions
    GROUP BY status, channel
    ORDER BY status, channel
    """
).show(truncate=False)

print(f"EDL_EVENT_COUNT={len(rows)}")
spark.stop()
