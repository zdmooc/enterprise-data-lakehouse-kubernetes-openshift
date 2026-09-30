# Derive from the locally validated I12 image; leave other runtime profiles alone.
FROM edl-jupyter:kind-2026-07-28
USER root
RUN python -m pip install --no-cache-dir GitPython==3.1.59 \
    && python -c "import git; assert git.__version__ == '3.1.59'"
USER 1000
