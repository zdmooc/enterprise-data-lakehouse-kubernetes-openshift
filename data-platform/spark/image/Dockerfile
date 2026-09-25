FROM spark:4.2.0-python3

USER root
RUN mkdir -p /opt/spark/work-dir/jobs && chgrp -R 0 /opt/spark/work-dir && chmod -R g=u /opt/spark/work-dir
COPY data-platform/spark/jobs/ /opt/spark/work-dir/jobs/
USER 185
