FROM spark:4.1.3-python3

ARG ICEBERG_VERSION=1.11.0

USER root

RUN python -m pip install --no-cache-dir kafka-python==3.0.11

RUN python - <<'PY'
import os
import urllib.request

version = os.environ.get("ICEBERG_VERSION", "1.11.0")
base = "https://repo1.maven.org/maven2/org/apache/iceberg"
artifacts = [
    (
        f"{base}/iceberg-spark-runtime-4.1_2.13/{version}/"
        f"iceberg-spark-runtime-4.1_2.13-{version}.jar",
        f"/opt/spark/jars/iceberg-spark-runtime-4.1_2.13-{version}.jar",
    ),
    (
        f"{base}/iceberg-aws-bundle/{version}/"
        f"iceberg-aws-bundle-{version}.jar",
        f"/opt/spark/jars/iceberg-aws-bundle-{version}.jar",
    ),
]
for url, target in artifacts:
    print(f"Downloading {url}")
    urllib.request.urlretrieve(url, target)
PY

RUN mkdir -p /opt/spark/work-dir/jobs &&     chgrp -R 0 /opt/spark/work-dir &&     chmod -R g=u /opt/spark/work-dir

COPY jobs/ /opt/spark/work-dir/jobs/

USER 185
