# Multi-stage Dockerfile - Option 4: Minimal CUDA base + pip
# Strategy: Fast pip wheels, minimal bloat, good reproducibility
# Base: NVIDIA CUDA runtime (2GB) + pip packages (~4GB) = ~6GB total
# Build time: ~15-20 minutes

# ============================================================================
# Stage 1: Builder - Install all packages
# ============================================================================
# FROM nvcr.io/nvidia/cuda-dl-base:25.11-cuda13.0-runtime-ubuntu24.04 AS builder
FROM nvcr.io/nvidia/cuda-dl-base:25.11-cuda13.0-runtime-ubuntu24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies and Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.12 \
    python3-pip \
    python3-dev \
    build-essential \
    curl \
    wget \
    git \
    ca-certificates \
    libssl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*



# install mambaforge (includes mamba and conda in one)
ENV CONDA_DIR=/opt/conda \
    PATH=/opt/conda/bin:$PATH \
    CONDA_ALWAYS_YES=true
RUN wget -q --show-progress https://github.com/conda-forge/miniforge/releases/download/24.1.2-0/Mambaforge-Linux-x86_64.sh -O /tmp/mambaforge.sh && \
    bash /tmp/mambaforge.sh -b -p $CONDA_DIR && \
    rm /tmp/mambaforge.sh && \
    conda clean -a -y

# Set python3.12 as default python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# Upgrade pip, setuptools, wheel
# RUN python -m pip install --upgrade pip setuptools wheel

# Copy requirements
# COPY requirements.txt /tmp/requirements.txt
COPY environment.yml /tmp/environment.yml

# Install Python packages from pip (wheels - fast and clean)
# Note: Using cu118 for PyTorch as cu131 wheels may not be available
# RUN python -m pip install --no-cache-dir --upgrade \
#     torch==2.5.1 --index-url https://download.pytorch.org/whl/cu118 && \
#     python -m pip install --no-cache-dir --upgrade \
#     -r /tmp/requirements.txt

# Install Python packages from conda (for complex dependencies)
RUN mamba env create -f /tmp/environment.yml && \
    conda clean -a -y

# Create Jupyter config directory
RUN mkdir -p /etc/jupyter && \
    cat > /etc/jupyter/jupyter_notebook_config.py <<'JUPYTER_EOF'
from os import getenv
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = int(getenv('JUPYTER_PORT', '8888'))
c.ServerApp.open_browser = False
c.ServerApp.allow_root = True
c.ServerApp.root_dir = '/work'
c.ServerApp.allow_origin = '*'
c.ServerApp.disable_check_xsrf = True
JUPYTER_EOF

# Create entrypoint script for HPC/SLURM integration
RUN mkdir -p /opt/bin && \
    cat > /opt/bin/ml-entrypoint.sh <<'ENTRYPOINT_EOF'
#!/bin/bash
set -e

echo "=== ML Module Container Entrypoint ==="
echo "Hostname: $(hostname)"
echo "Date: $(date)"

# SLURM environment detection
if [ -n "$SLURM_JOB_ID" ]; then
    echo "Running in SLURM job: $SLURM_JOB_ID"
    export WORKDIR="${SLURM_SUBMIT_DIR:-/work}"
    export TMPDIR="${SLURM_TMPDIR:-/tmp}"
else
    echo "Running outside SLURM"
    export WORKDIR="${WORKDIR:-/work}"
fi

# GPU detection and reporting
if command -v nvidia-smi >/dev/null 2>&1; then
    echo "GPUs detected:"
    nvidia-smi --query-gpu=index,name,driver_version,memory.total --format=csv,noheader
else
    echo "No GPUs detected"
fi

# Framework versions
python -c "
import sys
print(f'Python: {sys.version.split()[0]}')
try:
    import torch
    print(f'PyTorch: {torch.__version__} (CUDA available: {torch.cuda.is_available()})')
except: pass
try:
    import tensorflow as tf
    gpus = tf.config.list_physical_devices(\"GPU\")
    print(f'TensorFlow: {tf.__version__} (GPUs: {len(gpus)})')
except: pass
try:
    import jax
    print(f'JAX: {jax.__version__}')
except: pass
" 2>/dev/null || true

# Execute user command or start bash
if [ $# -eq 0 ]; then
    echo "Starting interactive bash shell..."
    exec /bin/bash
else
    echo "Executing command: $@"
    exec "$@"
fi
ENTRYPOINT_EOF

RUN chmod +x /opt/bin/ml-entrypoint.sh

# ============================================================================
# Stage 2: Runtime - Minimal image with only runtime dependencies
# ============================================================================
FROM nvcr.io/nvidia/cuda-dl-base:25.11-cuda13.0-runtime-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install only runtime dependencies (no build tools)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.12 \
    python3-pip \
    ca-certificates \
    libgomp1 \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set python3.12 as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1

# Copy installed packages from builder
COPY --from=builder /usr/local/lib/python3.12/dist-packages /usr/local/lib/python3.12/dist-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /etc/jupyter /etc/jupyter
COPY --from=builder /opt/bin/ml-entrypoint.sh /opt/bin/ml-entrypoint.sh

# Set environment variables
ENV PATH=/opt/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    CUDA_HOME=/usr/local/cuda \
    CUDA_PATH=/usr/local/cuda \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/cuda/extras/CUPTI/lib64

# HPC-specific environment variables
ENV NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    RAPIDS_NO_INITIALIZE=1 \
    OMP_NUM_THREADS=1 \
    MKL_NUM_THREADS=1 \
    NUMEXPR_NUM_THREADS=1 \
    DASK_DISTRIBUTED__COMM__TIMEOUTS__CONNECT=60s \
    DASK_DISTRIBUTED__COMM__TIMEOUTS__TCP=60s

# Create non-root user (optional, uncomment if needed for security)
# RUN useradd -m -s /bin/bash mluser && chown -R mluser /work
# USER mluser

WORKDIR /work

ENTRYPOINT ["/opt/bin/ml-entrypoint.sh"]
CMD ["/bin/bash"]

# Labels and metadata
LABEL maintainer="didier.barradasbautista@kaust.edu.sa" \
      version="2.0-option4" \
      description="ML Module Container - CUDA 13.0 + conda/mamba packages" \
      base="nvcr.io/nvidia/cuda-dl-base:25.11-cuda13.0-runtime-ubuntu24.04" \
      python="3.12" \
      frameworks="PyTorch , TensorFlow , JAX , RAPIDS"
