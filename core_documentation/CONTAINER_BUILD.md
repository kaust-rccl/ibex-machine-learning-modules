# Container Build Guide

**Complete guide for building Docker and Singularity containers locally**

---

## 📋 Overview

This guide covers building the ML module container in both Docker (for development/testing) and Singularity (for HPC deployment).

### Container Specifications
- **Base Image:** nvcr.io/nvidia/cuda-dl-base:25.11-cuda13.0-runtime-ubuntu24.04
- **Python:** 3.12
- **CUDA:** 13.0
- **Build System:** Mambaforge + mamba
- **Package Manager:** environment.yml (100+ packages)
- **Final Size:** ~6-7 GB
- **Build Time:** 30-60 minutes (Singularity), 15-20 minutes (Docker)

---

## 🐳 Docker Build (Local Development)

### Prerequisites
```bash
# Install Docker
# Mac: https://docs.docker.com/desktop/install/mac-install/
# Linux: https://docs.docker.com/engine/install/

# Verify installation
docker --version
docker ps

# For M-series Mac, ensure platform flag is used
uname -m  # Should show arm64
```

### Quick Build
```bash
cd /Users/barradd/Documents/GitHub/ibex-machine-learning-modules

# Build with platform flag (M-series Mac)
docker build --platform=linux/amd64 -f Dockerfile -t ml-module:latest .

# Build time: 15-20 minutes
# Final image: ~6-7 GB
```

### Build with Security Scanning
```bash
# Automated build + Trivy scan
bash bin/build-and-scan-docker.sh

# What it does:
# 1. Builds Docker image
# 2. Runs Trivy vulnerability scan
# 3. Generates reports in scan-reports/
# 4. Shows summary of vulnerabilities
```

### Multi-Stage Build Explained

The Dockerfile uses multi-stage builds for optimization:

**Stage 1: Builder** (large, with build tools)
```dockerfile
FROM nvcr.io/nvidia/cuda-dl-base:25.11-cuda13.0-runtime-ubuntu24.04 AS builder

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    wget \
    ca-certificates

# Install Mambaforge
RUN wget -O Mambaforge.sh https://github.com/conda-forge/miniforge/releases/download/24.1.2-0/Mambaforge-Linux-x86_64.sh

# Create environment from environment.yml
RUN mamba env create -f environment.yml -n ml-module
```

**Stage 2: Runtime** (smaller, runtime only)
```dockerfile
FROM nvcr.io/nvidia/cuda-dl-base:25.11-cuda13.0-runtime-ubuntu24.04

# Copy only the conda environment (no build tools)
COPY --from=builder /opt/conda /opt/conda

# Set environment variables
ENV PATH="/opt/conda/envs/ml-module/bin:$PATH"
```

**Benefits:**
- ✅ **Smaller image** - No build tools in final image
- ✅ **Faster deployments** - Less data to transfer
- ✅ **More secure** - Fewer packages = smaller attack surface

### Testing Docker Build
```bash
# Test basic execution
docker run --rm ml-module:latest python --version

# Test GPU access (requires NVIDIA Docker runtime)
docker run --rm --gpus all ml-module:latest python -c "import torch; print(torch.cuda.is_available())"

# Interactive shell
docker run --rm -it ml-module:latest /bin/bash

# Run tests
docker run --rm --gpus all ml-module:latest python tests/ml_env_test_script.py
```

### Troubleshooting Docker Build

**Issue: "permission denied while trying to connect to Docker daemon"**
```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER
newgrp docker

# Or use sudo
sudo docker build -t ml-module:latest .
```

**Issue: "exec /opt/conda/envs/ml-module/bin/python: no such file or directory" (M-series Mac)**
```bash
# MUST use --platform=linux/amd64 flag
docker build --platform=linux/amd64 -f Dockerfile -t ml-module:latest .

# Verify platform
docker inspect ml-module:latest | grep Architecture
# Should show: "Architecture": "amd64"
```

**Issue: "failed to solve with frontend dockerfile.v0: failed to build LLB: Context canceled"**
```bash
# Increase Docker resources
# Docker Desktop → Settings → Resources → Memory: 8GB+, Disk: 60GB+

# Clean up
docker system prune -a

# Retry
docker build --platform=linux/amd64 --no-cache -f Dockerfile -t ml-module:latest .
```

---

## 🔷 Singularity Build (HPC Deployment)

### Prerequisites
```bash
# Install Singularity or Apptainer
# RockyLinux 9:
sudo dnf install -y epel-release
sudo dnf install -y apptainer

# Verify
singularity --version  # or apptainer --version

# Requires sudo for full build
sudo singularity build --help
```

### Quick Build
```bash
cd /Users/barradd/Documents/GitHub/ibex-machine-learning-modules

# Build (requires sudo)
sudo singularity build ml_module.sif ml_module.def

# Build time: 30-60 minutes
# Output: ml_module.sif (~6-7 GB)
```

### Build Process Stages

The [ml_module.def](ml_module.def) definition file has these sections:

**1. Bootstrap** (5-10 min)
```
Bootstrap: docker
From: nvcr.io/nvidia/cuda-dl-base:25.11-cuda13.0-runtime-ubuntu24.04
```
Pulls NVIDIA CUDA base image with Python 3.12 pre-installed.

**2. %post - System Packages** (5 min)
```bash
apt-get update && apt-get install -y \
    build-essential git wget ca-certificates curl
```

**3. %post - Mambaforge** (10 min)
```bash
wget Mambaforge-Linux-x86_64.sh
bash Mambaforge-Linux-x86_64.sh -b -p /opt/conda
```

**4. %post - Environment Creation** (30-40 min)
```bash
mamba env create -f /tmp/environment.yml -n ml-module
```
This is the longest stage - installs 100+ packages.

**5. %post - RAPIDS Pip Packages** (5-10 min)
```bash
pip install cudf-cu13 cuml-cu13 cugraph-cu13 \
    --extra-index-url=https://pypi.nvidia.com
```

**6. %post - Cleanup** (2 min)
```bash
mamba clean -a -y
apt-get clean
rm -rf /var/lib/apt/lists/*
```

**7. %environment & %runscript**
Sets up container environment and default behavior.

### Build Options

**Option 1: From definition file** (recommended)
```bash
sudo singularity build ml_module.sif ml_module.def
```

**Option 2: From Docker image** (if Docker image exists)
```bash
# Build Docker first
docker build --platform=linux/amd64 -t ml-module:latest .

# Convert to Singularity
sudo singularity build ml_module.sif docker-daemon://ml-module:latest
```

**Option 3: Sandbox (for debugging)**
```bash
# Build as writable directory
sudo singularity build --sandbox ml_module/ ml_module.def

# Test and modify
sudo singularity shell --writable ml_module/

# Convert to SIF
sudo singularity build ml_module.sif ml_module/
```

### Testing Singularity Build
```bash
# Test basic execution
singularity exec ml_module.sif python --version

# Test GPU access
singularity exec --nv ml_module.sif python -c "import torch; print(torch.cuda.is_available())"

# Interactive shell
singularity shell --nv ml_module.sif

# Run tests
singularity exec --nv ml_module.sif python tests/ml_env_test_script.py

# Check container info
singularity inspect ml_module.sif
```

### Troubleshooting Singularity Build

**Issue: "FATAL: You must be the root user"**
```bash
# Singularity build requires sudo
sudo singularity build ml_module.sif ml_module.def

# Or use Apptainer in user mode (slower)
apptainer build --fakeroot ml_module.sif ml_module.def
```

**Issue: "while pulling image: error fetching image"**
```bash
# Check network connectivity
curl -I https://nvcr.io

# Use Docker pull first, then convert
docker pull nvcr.io/nvidia/cuda-dl-base:25.11-cuda13.0-runtime-ubuntu24.04
sudo singularity build ml_module.sif docker-daemon://nvcr.io/nvidia/cuda-dl-base:25.11-cuda13.0-runtime-ubuntu24.04
```

**Issue: "No space left on device"**
```bash
# Check disk space
df -h /tmp
df -h .

# Set temp directory
export SINGULARITY_TMPDIR=/path/to/large/disk/tmp
mkdir -p $SINGULARITY_TMPDIR

# Retry
sudo singularity build ml_module.sif ml_module.def
```

**Issue: "mamba: command not found"**
```bash
# Verify Mambaforge installation in %post section
# Check ml_module.def has correct PATH:
export PATH="/opt/conda/bin:$PATH"
```

---

## 🧪 Build Validation

### Automated Tests
```bash
# Run comprehensive environment test
./ml_module.sif python tests/ml_env_test_script.py
# or
singularity exec --nv ml_module.sif python tests/ml_env_test_script.py

# Check results
cat ml_env_test_results.json | jq '.summary'
```

### Manual Smoke Tests
```bash
# Test all frameworks
singularity exec ml_module.sif python -c "
import sys
print(f'Python: {sys.version}')

import torch
print(f'PyTorch: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')

import tensorflow as tf
print(f'TensorFlow: {tf.__version__}')
print(f'TF GPUs: {len(tf.config.list_physical_devices(\"GPU\"))}')

import jax
print(f'JAX: {jax.__version__}')

import cudf
print(f'cuDF: {cudf.__version__}')

import lightgbm
print(f'LightGBM: {lightgbm.__version__}')

print('✅ All frameworks imported successfully')
"
```

### GPU Tests
```bash
# Test GPU detection
singularity exec --nv ml_module.sif nvidia-smi

# Test CUDA in PyTorch
singularity exec --nv ml_module.sif python -c "
import torch
print(f'GPUs: {torch.cuda.device_count()}')
for i in range(torch.cuda.device_count()):
    print(f'  GPU {i}: {torch.cuda.get_device_name(i)}')
"

# Test RAPIDS cuDF GPU
singularity exec --nv ml_module.sif python -c "
import cudf
import numpy as np
df = cudf.DataFrame({'a': np.arange(1000000)})
print(f'cuDF GPU test: {df.a.sum()}')
"
```

---

## 🔄 Build Optimization

### Speed Optimization
```bash
# Use local package cache
export MAMBA_PKGS_DIRS=/local/fast/disk/mamba-cache
mamba env create -f environment.yml

# Parallel downloads
mamba install -y --parallel-downloads=8 package-name

# Skip tests during install
pip install --no-deps package-name
```

### Size Optimization
```dockerfile
# In Dockerfile or %post section

# Clean conda cache
mamba clean -a -y

# Clean apt cache
apt-get clean
rm -rf /var/lib/apt/lists/*

# Remove unnecessary files
rm -rf /opt/conda/pkgs/*
rm -rf /tmp/*
```

### Caching Strategy
```bash
# Docker: Use layer caching
# Expensive operations (apt-get, mamba) early in Dockerfile
# Frequently changing operations (COPY code) late

# Singularity: Use Docker layers
# Build Docker first with caching
docker build --platform=linux/amd64 -t ml-module:latest .
# Then convert
sudo singularity build ml_module.sif docker-daemon://ml-module:latest
```

---

## 🔧 Customization

### Adding Packages

**1. Edit environment.yml:**
```yaml
dependencies:
  - your-package  # No version pin, mamba resolves latest
  # or
  - your-package=1.2.3  # Pin specific version
```

**2. Rebuild container:**
```bash
# Docker
docker build --platform=linux/amd64 --no-cache -f Dockerfile -t ml-module:updated .

# Singularity
sudo singularity build ml_module_updated.sif ml_module.def
```

**3. Test new package:**
```bash
singularity exec ml_module_updated.sif python -c "import your_package"
```

### Modifying Base Image
```yaml
# In ml_module.def
Bootstrap: docker
From: nvcr.io/nvidia/cuda:12.2.0-cudnn8-runtime-ubuntu22.04  # Different CUDA version
```

Or in Dockerfile:
```dockerfile
FROM nvcr.io/nvidia/pytorch:24.01-py3  # PyTorch-optimized base
```

### Custom Entrypoint
```bash
# In ml_module.def %runscript section
#!/bin/bash
# Custom initialization
export MY_VAR="value"
exec python "$@"
```

---

## 📊 Build Comparison

| Aspect | Docker | Singularity |
|--------|--------|-------------|
| **Build Time** | 15-20 min | 30-60 min |
| **Build Privilege** | User (rootless possible) | Requires sudo |
| **Layer Caching** | ✅ Excellent | ⚠️ Limited |
| **Multi-stage** | ✅ Native | ⚠️ Workarounds |
| **HPC Deployment** | ❌ Rare | ✅ Standard |
| **GPU Access** | --gpus flag | --nv flag |
| **Size** | Same (~6-7 GB) | Same (~6-7 GB) |

### When to Use What

**Docker:**
- ✅ Local development on Mac/Linux
- ✅ Security scanning (Trivy)
- ✅ Rapid iteration (layer caching)
- ✅ CI/CD pipelines

**Singularity:**
- ✅ HPC cluster deployment
- ✅ Production environments
- ✅ Non-root execution
- ✅ Better filesystem integration

### Hybrid Workflow
```bash
# 1. Develop with Docker (fast iteration)
docker build --platform=linux/amd64 -f Dockerfile -t ml-module:dev .
docker run --rm --gpus all ml-module:dev python tests/

# 2. Test with Singularity (HPC simulation)
sudo singularity build ml_module_test.sif docker-daemon://ml-module:dev
singularity exec --nv ml_module_test.sif python tests/

# 3. Deploy to HPC with Singularity build
sudo singularity build ml_module.sif ml_module.def
```

---

## 🔒 Security Best Practices

### Vulnerability Scanning
```bash
# Scan Docker image
bash bin/build-and-scan-docker.sh

# Manual Trivy scan
trivy image --severity HIGH,CRITICAL ml-module:latest

# Generate SBOM
docker sbom ml-module:latest > ml-module-sbom.json
```

### Secure Build Practices
- ✅ Use official NVIDIA base images
- ✅ Pin package versions in production
- ✅ Scan for vulnerabilities regularly
- ✅ Minimize installed packages
- ✅ Clean caches and temporary files
- ✅ Don't include secrets in container
- ✅ Use multi-stage builds to reduce attack surface

### Runtime Security
```bash
# Singularity: Non-root by default
singularity exec ml_module.sif whoami  # Shows your username

# Read-only container
singularity exec --contain ml_module.sif python script.py

# Isolated network
singularity exec --net ml_module.sif python script.py
```

---

## 📚 Additional Resources

- **Deployment Guide:** [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **Quick Reference:** [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- **Package List:** [REQUIREMENTS_BREAKDOWN.md](REQUIREMENTS_BREAKDOWN.md)
- **Full Index:** [INDEX.md](INDEX.md)

### External Documentation
- **Docker:** https://docs.docker.com/
- **Singularity:** https://sylabs.io/docs/
- **Apptainer:** https://apptainer.org/docs/
- **NVIDIA NGC:** https://catalog.ngc.nvidia.com/
- **Trivy:** https://aquasecurity.github.io/trivy/

---

**Last Updated:** January 2026  
**Version:** 2025.09  
**Container:** ml_module_2025.09.sif
