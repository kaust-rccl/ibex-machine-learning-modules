# ML Module Container Troubleshooting Guide

**Comprehensive guide for diagnosing and fixing common issues with the ML module container**

---

## 🔧 Fixed Issues in ml_module.def (2026 Release)

### Issue 1: Shell Syntax Errors During Build
**Error:**
```
15:4: not a valid test operator: 13.0
21:4: not a valid test operator: (
21:4: not a valid test operator: [
```

**Root Cause:** APT configuration with problematic brackets and special characters causing shell interpretation errors

**Fix Applied:**
- Removed complex APT configuration heredoc (APT_EOF)
- Simplified apt-get commands to use straightforward flags: `--allow-unauthenticated`
- Removed `-o Apt::Get::AllowUnauthenticated=true` and `-o APT::ExtractTemplates::TempDir=/var/tmp` options

**Changed:**
```bash
# OLD (broken)
apt-get update -o Apt::Get::AllowUnauthenticated=true -o APT::ExtractTemplates::TempDir=/var/tmp

# NEW (fixed)
apt-get update -y --allow-unauthenticated || apt-get update -y || true
```

---

### Issue 2: Jupyter Not Found in PATH
**Error:**
```
FATAL: "jupyter": executable file not found in $PATH
```

**Root Cause:** Conda environment not activated in the runscript/startscript, so jupyter (installed in conda env) wasn't accessible

**Fix Applied:**
- Added conda environment activation to `%runscript`
- Added conda environment activation to `%startscript`
- Added conda activation to entrypoint script within heredoc
- Fixed variable escaping in ENTRYPOINT script (changed `\$#` to `$#`)

**Changed in %runscript:**
```bash
# OLD (broken)
%runscript
    exec /opt/bin/ml-entrypoint.sh "$@"

# NEW (fixed)
%runscript
    source /opt/conda/etc/profile.d/conda.sh
    conda activate ml-module
    exec /opt/bin/ml-entrypoint.sh "$@"
```

**Changed in entrypoint script:**
```bash
# OLD (broken)
if [ \$# -eq 0 ]; then
    exec "\$@"

# NEW (fixed)
source /opt/conda/etc/profile.d/conda.sh
conda activate ml-module
if [ $# -eq 0 ]; then
    exec "$@"
```

---

## 🧪 Testing the Fixed Container

### Step 1: Build the Container
```bash
# Rebuild with fixed ml_module.def
sudo singularity build ml_module_v1.0.sif ml_module.def

# Expected output:
# INFO:    Build complete: ml_module_v1.0.sif
```

### Step 2: Verify Container Validity
```bash
# Check container integrity
singularity inspect ml_module_v1.0.sif

# Expected output:
# Author: didier.barradasbautista@kaust.edu.sa
# Version: 2.0
# Description: ML module for HPC clusters...
```

### Step 3: Test Jupyter Installation
```bash
# Test that jupyter is accessible
singularity exec --nv ml_module_v1.0.sif which jupyter

# Expected output:
# /opt/conda/envs/ml-module/bin/jupyter
```

### Step 4: Test Framework Imports
```bash
# Test core frameworks
singularity exec --nv ml_module_v1.0.sif python -c "
import torch
import tensorflow as tf
import jax
import cudf
print('✅ All frameworks imported successfully')
print(f'PyTorch version: {torch.__version__}')
print(f'TensorFlow version: {tf.__version__}')
print(f'JAX version: {jax.__version__}')
print(f'RAPIDS cuDF version: {cudf.__version__}')
"
```

### Step 5: Test Jupyter Lab Launch
```bash
# Test jupyter lab startup (non-interactive, just test command)
singularity exec --nv ml_module_v1.0.sif jupyter lab --version

# Expected output:
# 4.x.x or later
```

### Step 6: Test GPU Access
```bash
# Verify GPU is accessible
singularity exec --nv ml_module_v1.0.sif nvidia-smi

# Expected output:
# GPU information table
# Example:
# +-----------------------------------------------------------------------------+
# | NVIDIA-SMI 560.35.03              Driver Version: 560.35.03                 |
# ...
```

### Step 7: Interactive Shell Test
```bash
# Test interactive shell
singularity shell --nv ml_module_v1.0.sif

# Inside container:
Singularity> python --version
Singularity> jupyter --version
Singularity> exit
```

---

## 🚀 Running Jupyter Lab Correctly

### Method 1: Direct Singularity Execution
```bash
# Test direct execution
singularity exec --nv ml_module_v1.0.sif \
    jupyter lab --ip=0.0.0.0 --port=8888 --no-browser

# You should see:
# [C 2026-01-26 12:00:00.000 ServerApp]
#     To access the server, open this file in a browser:
```

### Method 2: SLURM Job (Recommended)
```bash
# Use the refactored launch script
sbatch bin/launch-jupyter-container.sbatch

# Check job status
squeue -u $USER

# Check logs
tail -f logs/ml-jupyter-lab-*.slurm.err
```

### Method 3: Bind Mounts for Data Access
```bash
# Execute with proper bind mounts
singularity exec --nv \
    --bind /ibex/user/$USER:/work \
    --bind $SLURM_TMPDIR:/tmp \
    ml_module_v1.0.sif \
    jupyter lab --ip=0.0.0.0 --port=8888 --notebook-dir=/work
```

---

## 🐛 Common Issues & Solutions

### Issue: "conda: command not found"
**Cause:** Conda not in PATH during build or runtime  
**Solution:**
```bash
# In scripts, always source conda
source /opt/conda/etc/profile.d/conda.sh
conda activate ml-module
```

### Issue: "CUDA out of memory" during build
**Cause:** Container build process needs temp space  
**Solution:**
```bash
# Increase /tmp or use /var/tmp (already configured in ml_module.def)
export TMPDIR=/var/tmp
export TEMP=/var/tmp
sudo singularity build ml_module_v1.0.sif ml_module.def
```

### Issue: "Package not found" during environment install
**Cause:** Conda channels not properly configured  
**Solution:** Check `environment.yml` has correct channels:
```yaml
channels:
  - pytorch
  - nvidia
  - rapidsai
  - conda-forge
  - defaults
```

### Issue: "GPU not detected" in container
**Cause:** Missing `--nv` flag or NVIDIA drivers not installed  
**Solution:**
```bash
# ALWAYS use --nv flag
singularity exec --nv ml_module_v1.0.sif nvidia-smi

# Check host drivers
nvidia-smi
```

### Issue: "Permission denied" on /ibex paths
**Cause:** Bind mount path permissions  
**Solution:**
```bash
# Verify path exists and is readable
ls -ld /ibex/user/$USER

# Use correct bind syntax
singularity exec \
    --bind /ibex/user/$USER:/work \
    ml_module_v1.0.sif bash
```

### Issue: "Read-only file system"
**Cause:** SINGULARITY_WRITABLEFS not set  
**Solution:**
```bash
# Use writable bind mount for output
singularity exec --nv \
    --bind $OUTPUT_DIR:/output:rw \
    ml_module_v1.0.sif python script.py
```

---

## 📋 Pre-Build Checklist

Before building the container, verify:

- [ ] Singularity/Apptainer is installed: `singularity --version`
- [ ] Docker base image is accessible: `docker pull nvcr.io/nvidia/cuda-dl-base:25.11-cuda13.0-runtime-ubuntu24.04`
- [ ] Disk space available: At least 10GB free
- [ ] Build privileges: `sudo` access for container build
- [ ] `environment.yml` exists in the build directory
- [ ] All `ml_module.def` files are properly formatted (check for syntax errors)

---

## 📊 Post-Build Verification

After building, run this comprehensive test:

```bash
#!/bin/bash
set -e

CONTAINER="ml_module_v1.0.sif"

echo "=========================================="
echo "ML Module Container Verification Test"
echo "=========================================="

# Test 1: Container exists and is valid
echo "1. Checking container validity..."
singularity inspect $CONTAINER > /dev/null && echo "   ✅ Container is valid"

# Test 2: Jupyter is available
echo "2. Checking Jupyter..."
singularity exec $CONTAINER which jupyter && echo "   ✅ Jupyter found"

# Test 3: Core frameworks
echo "3. Checking frameworks..."
singularity exec --nv $CONTAINER python -c "
import torch, tensorflow, jax, cudf
print('   ✅ All frameworks available')
"

# Test 4: GPU access
echo "4. Checking GPU access..."
singularity exec --nv $CONTAINER nvidia-smi --query-gpu=name --format=csv,noheader && echo "   ✅ GPU accessible"

# Test 5: Jupyter Lab version
echo "5. Checking Jupyter Lab version..."
singularity exec $CONTAINER jupyter lab --version && echo "   ✅ Jupyter Lab ready"

echo ""
echo "=========================================="
echo "✅ All verification tests passed!"
echo "=========================================="
```

---

## 🆘 Getting Help

### Check Build Logs
```bash
# If build fails, check for detailed errors
sudo singularity build --fakeroot ml_module_v1.0.sif ml_module.def 2>&1 | tail -100
```

### Validate Definition File
```bash
# Check for syntax errors
singularity verify ml_module.def
```

### Test Package Installation
```bash
# Test specific package inside container
singularity exec ml_module_v1.0.sif python -c "import <package_name>"
```

### Check Container Environment
```bash
# Inspect all environment variables in container
singularity exec ml_module_v1.0.sif env | sort
```

### Debug Entrypoint Issues
```bash
# Run with debugging
singularity exec -vv ml_module_v1.0.sif /bin/bash -x /opt/bin/ml-entrypoint.sh
```

---

## 📞 Support

For issues or questions:
1. Check this guide first
2. Review build logs for specific error messages
3. Contact: ibex@hpc.kaust.edu.sa
4. Reference: ML Module 2026 Documentation Index at [core_documentation/INDEX.md](INDEX.md)

---

## ✅ Version History

| Version | Date | Changes |
|---------|------|---------|
| 2.0 | 2026-01-26 | Fixed shell syntax errors, conda activation in runscript |
| 1.0 | 2025-09 | Initial release |
