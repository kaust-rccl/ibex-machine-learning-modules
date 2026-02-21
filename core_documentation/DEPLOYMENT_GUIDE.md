# ML Module Deployment Guide

**Complete guide for deploying the machine learning module to Ibex HPC cluster**

---

## 📋 Overview

This guide covers deploying the ML module as a Singularity container on RockyLinux 9 HPC cluster with SLURM scheduling.

### What You're Deploying
- **Container:** ml_module_2025.09.sif (~6-7 GB)
- **Base:** NVIDIA CUDA-DL-Base (CUDA 13.0, Python 3.12)
- **Packages:** 100+ ML/AI libraries (RAPIDS, PyTorch, TensorFlow, JAX, etc.)
- **Build Method:** Mambaforge + environment.yml
- **Access:** Environment module system

---

## 🎯 Prerequisites

### System Requirements
- **OS:** RockyLinux 9 (or compatible)
- **Container Runtime:** Singularity ≥3.8 or Apptainer ≥1.0
- **GPU Drivers:** NVIDIA drivers compatible with CUDA 13.0
- **Scheduler:** SLURM with GPU support (`--gpus` flag)
- **Disk Space:** 10 GB free for build + final image
- **Build Privileges:** sudo access for container build

### Software Checks
```bash
# Check Singularity/Apptainer
singularity --version  # or apptainer --version

# Check NVIDIA drivers
nvidia-smi

# Check CUDA compatibility
nvidia-smi | grep "CUDA Version"  # Should be ≥13.0

# Check SLURM
sinfo
```

---

## 🚀 Quick Deployment (Automated)

### Option 1: Automated Setup Script
```bash
# Clone repository
cd /sw/sources/machine_learning
git clone https://github.com/D-Barradas/ibex-machine-learning-modules.git
cd ibex-machine-learning-modules

# Run setup (builds container + creates module)
bash bin/setup_install.sh
```

**What it does:**
1. Creates target directory: `2025.09/singularity/`
2. Runs `bin/run_install.sh` which:
   - Clones repo to build location
   - Builds Singularity container from `ml_module.def`
   - Verifies container integrity
3. Generates environment module file
4. Installs to `/sw/rl9g/modulefiles/applications/machine_learning/2025.09/singularity`

**Expected time:** 30-60 minutes

---

## 📦 Manual Deployment (Step-by-Step)

### Step 1: Prepare Build Environment
```bash
# Set variables
export VERSION="2025.09"
export CONTAINER_NAME="ml_module_${VERSION}.sif"
export PREFIX="/sw/applications/machine_learning"
export TARGET_DIR="${PREFIX}/${VERSION}/singularity"

# Create directories
mkdir -p $TARGET_DIR
chmod g+w $TARGET_DIR
```

### Step 2: Clone Repository
```bash
# Clone specific version
cd /sw/sources/machine_learning
git clone https://github.com/D-Barradas/ibex-machine-learning-modules.git -b machine-learning-${VERSION} ml-build

cd ml-build
```

### Step 3: Build Singularity Container
```bash
# Build (requires sudo)
sudo singularity build ${TARGET_DIR}/${CONTAINER_NAME} ml_module.def

# Expected output:
# - Build time: 30-60 minutes
# - Size: ~6-7 GB
# - Location: /sw/applications/machine_learning/2025.09/singularity/ml_module_2025.09.sif
```

**Build stages:**
1. **Bootstrap** (5 min) - Pull NVIDIA CUDA base image
2. **Mambaforge** (10 min) - Install conda package manager
3. **Environment** (30-40 min) - Install all packages from environment.yml
4. **RAPIDS pip** (5-10 min) - Install RAPIDS wheels from NVIDIA PyPI
5. **Finalize** (5 min) - Configure entrypoint and environment

### Step 4: Verify Container
```bash
# Check file exists and size
ls -lh ${TARGET_DIR}/${CONTAINER_NAME}

# Test execution
singularity exec ${TARGET_DIR}/${CONTAINER_NAME} python --version

# Test GPU access
singularity exec --nv ${TARGET_DIR}/${CONTAINER_NAME} python -c "import torch; print(torch.cuda.is_available())"

# Test imports
singularity exec ${TARGET_DIR}/${CONTAINER_NAME} python -c "
import torch, tensorflow as tf, jax, cudf, lightgbm
print('✅ All frameworks loaded successfully')
"
```

### Step 5: Generate Environment Module
```bash
# Set module variables
export MODULESHOME="/sw/rl9g/modulefiles/applications/machine_learning"
export PACKAGE="machine_learning"

# Generate modulefile
bash bin/generate_modulefile.sh

# Expected output:
# - Modulefile: /sw/rl9g/modulefiles/applications/machine_learning/2025.09/singularity
```

### Step 6: Test Module
```bash
# Load module
module load machine_learning/2025.09/singularity

# Check environment variables
echo $ML_CONTAINER_PATH
echo $SINGULARITY_IMAGE

# Test execution
singularity exec $ML_CONTAINER_PATH python -c "print('Module loaded successfully')"
```

---

## 🔄 Rebuilding Existing Module

### When to Rebuild
- Package updates needed
- Bug fixes in container
- New features added to environment.yml
- Security patches

### Rebuild Process
```bash
cd /sw/sources/machine_learning/ibex-machine-learning-modules

# Update repository
git pull origin machine-learning-2025.09

# Run rebuild script
bash bin/rebuild_module.sh
```

**What it does:**
1. Cleans up old build artifacts
2. Removes existing container (backup created)
3. Rebuilds container from updated definition
4. Regenerates module file
5. Logs all steps to `rebuild_module.log`

---

## 📝 Environment Module Details

### Module File Location
```
/sw/rl9g/modulefiles/applications/machine_learning/2025.09/singularity
```

### Module File Contents
```tcl
#%Module 1.0
set name            machine_learning
set version         2025.09
set container_path  /sw/applications/machine_learning/2025.09/singularity/ml_module_2025.09.sif

# Environment variables
setenv ML_CONTAINER_PATH $container_path
setenv SINGULARITY_IMAGE $container_path
setenv SINGULARITY_CACHEDIR /tmp/singularity-cache-$USER

# Bind paths for cluster
setenv SINGULARITYENV_BIND "/sw,/home,/scratch,/project"

# GPU support
setenv SINGULARITYENV_NVIDIA_VISIBLE_DEVICES all
setenv SINGULARITYENV_NVIDIA_DRIVER_CAPABILITIES compute,utility

# Container paths
setenv SINGULARITYENV_PATH "/opt/conda/envs/ml-module/bin:/opt/bin:$PATH"
```

### User Experience
```bash
$ module load machine_learning/2025.09/singularity
Loading module for machine_learning 2025.09
Container: /sw/applications/machine_learning/2025.09/singularity/ml_module_2025.09.sif
machine_learning 2025.09 is now loaded

To run a command in the container:
  singularity exec $ML_CONTAINER_PATH <command>

To open an interactive shell:
  singularity shell $ML_CONTAINER_PATH
```

---

## 🧪 Testing Deployment

### Quick Validation
```bash
# Load module
module load machine_learning/2025.09/singularity

# Test 1: Python version
singularity exec $ML_CONTAINER_PATH python --version
# Expected: Python 3.12.x

# Test 2: GPU access
singularity exec --nv $ML_CONTAINER_PATH python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}')"
# Expected: CUDA: True

# Test 3: All frameworks
singularity exec $ML_CONTAINER_PATH python -c "
import torch, tensorflow as tf, jax, cudf
print('✅ All frameworks imported')
"
```

### Comprehensive Tests
```bash
# Run full environment test
singularity exec --nv $ML_CONTAINER_PATH python tests/ml_env_test_script.py

# Check results
cat ml_env_test_results.json

# Run distributed computing test
singularity exec --nv $ML_CONTAINER_PATH python tests/distributed_test_script.py

# Check results
cat distributed_test_results.json
```

### SLURM Integration Test
```bash
# Submit test job
sbatch <<'EOF'
#!/bin/bash
#SBATCH --job-name=ml-test
#SBATCH --time=00:10:00
#SBATCH --gpus=1
#SBATCH --partition=debug

module load machine_learning/2025.09/singularity

singularity exec --nv $ML_CONTAINER_PATH python -c "
import torch
print(f'PyTorch version: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
print(f'GPU count: {torch.cuda.device_count()}')
if torch.cuda.is_available():
    print(f'GPU name: {torch.cuda.get_device_name(0)}')
"
EOF
```

---

## 🔧 Configuration & Customization

### Bind Mounts
Edit module file to add custom bind paths:
```tcl
# Add custom project directories
setenv SINGULARITYENV_BIND "/sw,/home,/scratch,/project,/custom/path"
```

### Container Cache
Configure per-user or shared cache:
```tcl
# Per-user cache (default)
setenv SINGULARITY_CACHEDIR /tmp/singularity-cache-$USER

# Shared cache (faster for multiple users)
setenv SINGULARITY_CACHEDIR /sw/cache/singularity
```

### Environment Variables
Pass environment variables into container:
```bash
# In SLURM job
export MY_VAR="value"
singularity exec --env MY_VAR=$MY_VAR $ML_CONTAINER_PATH python script.py

# Or set in module file
setenv SINGULARITYENV_MY_VAR "value"
```

---

## 🔒 Security Considerations

### Container Security Features
- ✅ **Non-root execution** - Container runs as user
- ✅ **Read-only filesystem** - Base image is immutable
- ✅ **Bind mount isolation** - Only specified paths accessible
- ✅ **GPU isolation** - NVIDIA runtime controls GPU access
- ✅ **Network isolation** - Configurable network policies

### Access Control
```bash
# Set container permissions
chmod 644 ${TARGET_DIR}/${CONTAINER_NAME}

# Set directory permissions
chmod 755 ${TARGET_DIR}
chgrp hpc-users ${TARGET_DIR}
```

### Vulnerability Scanning
```bash
# Scan container (requires Docker)
bash bin/build-and-scan-docker.sh

# Review reports
ls -l scan-reports/
```

---

## 🐛 Troubleshooting

### Build Failures

**"No space left on device"**
```bash
# Check disk space
df -h /tmp
df -h $TARGET_DIR

# Clean up
rm -rf /tmp/singularity-*
rm -rf ${TARGET_DIR}/machine_learning-module
```

**"Base image pull failed"**
```bash
# Test network connectivity
curl -I https://nvcr.io

# Use Docker pull first
docker pull nvcr.io/nvidia/cuda-dl-base:25.11-cuda13.0-runtime-ubuntu24.04
singularity build ml_module.sif docker-daemon://nvcr.io/nvidia/cuda-dl-base:25.11-cuda13.0-runtime-ubuntu24.04
```

**"Mambaforge download failed"**
```bash
# Manually download
wget https://github.com/conda-forge/miniforge/releases/download/24.1.2-0/Mambaforge-Linux-x86_64.sh

# Update ml_module.def to use local file
# Edit %post section
```

### Runtime Issues

**"CUDA not available"**
```bash
# Check NVIDIA drivers
nvidia-smi

# Test with --nv flag
singularity exec --nv $ML_CONTAINER_PATH nvidia-smi

# Check CUDA version mismatch
nvidia-smi | grep "CUDA Version"  # Should be ≥13.0
```

**"Module not found"**
```bash
# Check package installation
singularity exec $ML_CONTAINER_PATH pip list | grep package-name

# Verify environment.yml
cat environment.yml | grep package-name
```

**"Permission denied"**
```bash
# Check file permissions
ls -l $ML_CONTAINER_PATH

# Check bind mount permissions
ls -ld /project/$USER

# Try read-only bind
singularity exec --bind /project/$USER:/data:ro $ML_CONTAINER_PATH python script.py
```

### Module Issues

**"Module not found"**
```bash
# Check module path
module av machine_learning

# Verify modulefile exists
ls -l /sw/rl9g/modulefiles/applications/machine_learning/2025.09/singularity

# Reload module cache
module spider machine_learning
```

---

## 📊 Monitoring & Maintenance

### Usage Monitoring
```bash
# Track container usage
sacct -u ALL --format=JobID,JobName,Partition,State,Start,End,NodeList | grep ml-

# Disk space
du -sh ${TARGET_DIR}/${CONTAINER_NAME}
```

### Updates & Patches
```bash
# Check for updates
cd /sw/sources/machine_learning/ibex-machine-learning-modules
git fetch origin
git log HEAD..origin/machine-learning-2025.09

# Apply updates
git pull origin machine-learning-2025.09
bash bin/rebuild_module.sh
```

### Backup & Recovery
```bash
# Backup container
cp ${TARGET_DIR}/${CONTAINER_NAME} ${TARGET_DIR}/${CONTAINER_NAME}.backup

# Backup modulefile
cp /sw/rl9g/modulefiles/applications/machine_learning/2025.09/singularity \
   /sw/rl9g/modulefiles/applications/machine_learning/2025.09/singularity.backup
```

---

## 📚 Additional Resources

- **Quick Reference:** [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- **Container Building:** [CONTAINER_BUILD.md](CONTAINER_BUILD.md)
- **Migration Guide:** [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)
- **Package List:** [REQUIREMENTS_BREAKDOWN.md](REQUIREMENTS_BREAKDOWN.md)
- **Full Index:** [INDEX.md](INDEX.md)

---

## 📞 Support

**Build Issues:** Review install.log and check disk space/network  
**Runtime Issues:** Check GPU drivers and module configuration  
**Package Issues:** Verify environment.yml and rebuild container  
**Module Issues:** Check modulefile syntax and permissions  

**HPC Support:** Contact Ibex cluster support team

---

**Last Updated:** January 2026  
**Version:** 2025.09  
**Container:** ml_module_2025.09.sif
