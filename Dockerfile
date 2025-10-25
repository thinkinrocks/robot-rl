FROM nvidia/cuda:12.6.2-runtime-ubuntu22.04 AS base

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

RUN apt-get update && apt-get install -y \
    software-properties-common \
    curl \
    git \
    ffmpeg \
    libglvnd0 \
    libgl1 \
    libglx0 \
    libegl1 \
    libgles2 \
    && add-apt-repository ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install -y python3.11 python3.11-venv python3.11-distutils \
    && apt-get remove -y python3.10 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1 \
    && curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:bookworm-slim /usr/local/bin/uv /bin/uv

CMD ["python3.11"]

FROM base AS mujoco-playground

WORKDIR /workspace

RUN uv venv /opt/venv --seed
ENV UV_PYTHON=/opt/venv/bin/python
RUN uv pip install ipykernel
RUN uv pip install jupyterlab

# Copy example notebooks to /examples (not affected by volume mount)
COPY mujoco-playground/ /examples/

# Register the venv kernel and make it the only available kernel
RUN /opt/venv/bin/python -m ipykernel install --prefix=/workspace/.venv --name=python3 --display-name="Python 3.11 (venv)"

# Configure Jupyter to only use kernels from the venv
ENV JUPYTER_PATH=/opt/venv/share/jupyter
ENV JUPYTER_DATA_DIR=/opt/venv/share/jupyter
ENV JUPYTER_BASE_URL=/
ENV JUPYTER_TOKEN=aaltoes-robotics-2025

# Create entrypoint script that copies examples to workspace if they don't exist
RUN echo '#!/bin/bash\n\
for file in /examples/*.ipynb; do\n\
  basename=$(basename "$file")\n\
  if [ ! -f "/workspace/$basename" ]; then\n\
    echo "Copying example: $basename"\n\
    cp "$file" "/workspace/$basename"\n\
  fi\n\
done\n\
exec "$@"' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD /opt/venv/bin/jupyter lab --ip=0.0.0.0 --allow-root --no-browser --ServerApp.base_url=${JUPYTER_BASE_URL} --ServerApp.token=${JUPYTER_TOKEN}
