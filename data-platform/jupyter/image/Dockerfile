FROM quay.io/jupyter/scipy-notebook:2026-07-28

USER root

RUN python -m pip install --no-cache-dir trino==0.340.0 &&     mkdir -p /opt/edl/examples &&     chgrp -R 0 /home/jovyan /opt/conda /opt/edl &&     chmod -R g=u /home/jovyan /opt/conda /opt/edl

COPY sample/ /opt/edl/examples/

USER 1000
