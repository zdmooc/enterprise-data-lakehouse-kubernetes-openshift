from pyspark.sql import SparkSession
from pyspark.sql import functions as F

spark = SparkSession.builder.appName("edl-transactions-aggregate").getOrCreate()

rows = [
    ("txn-0001", 125.40, "EUR", "ACCEPTED", "MOBILE", "FR", 84),
    ("txn-0002", 90.00, "EUR", "ACCEPTED", "WEB", "FR", 102),
    ("txn-0003", 250.10, "EUR", "REJECTED", "MOBILE", "DE", 64),
    ("txn-0004", 19.99, "EUR", "ACCEPTED", "POS", "FR", 45),
    ("txn-0005", 800.00, "EUR", "PENDING", "WEB", "BE", 310),
]

columns = [
    "transactionId",
    "amount",
    "currency",
    "status",
    "channel",
    "country",
    "latencyMs",
]

df = spark.createDataFrame(rows, columns)

curated = (
    df.withColumn("amount", F.round(F.col("amount"), 2))
      .withColumn(
          "latencyBucket",
          F.when(F.col("latencyMs") < 100, "FAST")
           .when(F.col("latencyMs") < 250, "NORMAL")
           .otherwise("SLOW"),
      )
)

summary = (
    curated.groupBy("status", "channel")
           .agg(
               F.count("*").alias("transactionCount"),
               F.round(F.sum("amount"), 2).alias("totalAmount"),
               F.round(F.avg("latencyMs"), 2).alias("avgLatencyMs"),
           )
           .orderBy("status", "channel")
)

print("=== EDL_CURATED_SAMPLE ===")
curated.show(truncate=False)
print("=== EDL_AGGREGATE_RESULT ===")
summary.show(truncate=False)

spark.stop()
