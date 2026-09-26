import os
import trino

host = os.getenv("TRINO_HOST", "edl-trino.edl-data.svc")
port = int(os.getenv("TRINO_PORT", "8080"))

conn = trino.dbapi.connect(
    host=host,
    port=port,
    user="data-analyst",
    catalog="polaris",
    schema="analytics",
)

cur = conn.cursor()
cur.execute(
    """
    SELECT status, channel,
           count(*) AS transaction_count,
           round(sum(amount), 2) AS total_amount
    FROM transactions
    GROUP BY status, channel
    ORDER BY status, channel
    """
)

rows = cur.fetchall()
if not rows:
    raise RuntimeError("No lakehouse rows returned")

for row in rows:
    print(row)

print(f"EDL_JUPYTER_LAKEHOUSE_ROWS={len(rows)}")
