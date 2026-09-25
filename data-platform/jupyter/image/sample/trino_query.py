import os
import trino

host = os.getenv("TRINO_HOST", "edl-trino.edl-data.svc")
port = int(os.getenv("TRINO_PORT", "8080"))

conn = trino.dbapi.connect(
    host=host,
    port=port,
    user="data-analyst",
    catalog="tpch",
    schema="tiny",
)

cur = conn.cursor()
cur.execute(
    """
    SELECT nationkey, count(*) AS customers
    FROM customer
    GROUP BY nationkey
    ORDER BY customers DESC
    LIMIT 10
    """
)

for row in cur.fetchall():
    print(row)
