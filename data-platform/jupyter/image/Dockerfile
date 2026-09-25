FROM quay.io/jupyter/scipy-notebook:2026-07-28

USER root

RUN python -m pip install --no-cache-dir trino==0.340.0 &&     chgrp -R 0 /home/jovyan /opt/conda &&     chmod -R g=u /home/jovyan /opt/conda

COPY sample/ /home/jovyan/work/

USER 1000
