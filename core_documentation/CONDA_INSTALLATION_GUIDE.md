# Conda ML Module Installation Guide

**Complete guide for installing the ML module as a conda environment locally or on HPC cluster**

---

## 📋 Overview

This guide covers setting up the ML module using conda, offering a lightweight alternative to containerized deployment. Conda environments can be created locally on login nodes or via SLURM jobs on compute nodes.

### Key Features
- **Fast Setup:** 20-40 minutes for environment creation
- **Flexible Deployment:** Works on login nodes or via SLURM
- **Direct Python Access:** No container overhead
- **GPU Support:** Built-in CUDA/cuDF configurations
- **Module Integration:** Optional TCL modulefile generation for HPC clusters

---

## 🎯 Quick Start

### Minimum Setup (3 steps)

1. **Update environment.yml with your dependencies**
   ```bash
   cd /ibex/user/barradd/ibex-machine-learning-modules
   # Edit environment.yml with your packages
   ```

2. **Create conda environment**
   ```bash
   # Option A: Direct (on login node)
   bash bin/setup_install_conda_install.sh
   
   # Option B: SLURM job (on compute node)
   sbatch bin/create-conda-env_conda_install.sbatch
   ```

3. **Activate and verify**
   ```bash
   conda activate env/
   python -c "import torch; print(torch.__version__)"
   ```

---

## 🚀 Installation Methods

### Method 1: Direct Installation (Login Node)

**Best for:** Quick testing, small environments, development

#### Prerequisites
```bash
# Verify conda is available
conda --version
# or
mamba --version

# Activate conda if needed
source /ibex/user/${USER}/miniconda3/bin/activate
```

#### Installation Steps

```bash
# Step 1: Navigate to project root
cd /ibex/user/barradd/ibex-machine-learning-modules

# Step 2: Run setup script
bash bin/setup_install_conda_install.sh

# Expected output:
# ✓ Conda/Mamba found in PATH
# [INFO] Creating target environment directory...
# [INFO] Creating conda environment at: ./env
# [INFO] Installing packages from: ./environment.yml
# [INFO] Environment created successfully
```

#### What It Does
1. Validates environment.yml exists
2. Activates conda
3. Creates environment at `./env`
4. Installs all packages from environment.yml
5. Generates installation log: `conda_install.log`

#### Verification
```bash
# Quick check
conda activate env/
python --version

# Full verification
bash bin/verify_install_conda_install.sh env/
```

**Pros:**
- Fast (20-30 minutes)
- Direct feedback
- Easy to debug
- No queue wait time

**Cons:**
- Uses login node resources
- May impact cluster
- Not recommended for large environments

---

### Method 2: SLURM Job (Compute Node)

**Best for:** Production environments, large dependencies, cluster best practices

#### Prerequisites
```bash
# Check SLURM availability
sinfo
sbatch --version

# Verify project directory accessibility
ls -la /ibex/user/barradd/ibex-machine-learning-modules/
```

#### Submission Steps

```bash
# Step 1: Navigate to project root
cd /ibex/user/barradd/ibex-machine-learning-modules

# Step 2: Submit SLURM job
sbatch bin/create-conda-env_conda_install.sbatch

# Expected output:
# Submitted batch job 45234567

# Step 3: Monitor job
squeue -u ${USER} -j 45234567
# or
tail -f logs/conda-env-create-45234567-slurm.err
```

#### Job Configuration

Edit these SLURM parameters in `bin/create-conda-env_conda_install.sbatch`:

```bash
#SBATCH --time=02:00:00          # Increase if install takes longer
#SBATCH --gpus-per-node=v100:1   # GPU requirement
#SBATCH --cpus-per-gpu=4         # CPU cores
#SBATCH --mem=32G                # Memory
#SBATCH --partition=batch        # Queue name
```

#### Recommended Configurations

**Small environment (< 5 GB)**
```bash
#SBATCH --time=00:45:00
#SBATCH --cpus-per-gpu=2
#SBATCH --mem=16G
```

**Medium environment (5-15 GB)**
```bash
#SBATCH --time=01:30:00
#SBATCH --cpus-per-gpu=4
#SBATCH --mem=32G
```

**Large environment (> 15 GB)**
```bash
#SBATCH --time=02:30:00
#SBATCH --cpus-per-gpu=6
#SBATCH --mem=64G
```

#### Output Location
```
logs/conda-env-create-${JOB_ID}-slurm.out  # Standard output
logs/conda-env-create-${JOB_ID}-slurm.err  # Error messages
```

**Pros:**
- Best practice for clusters
- Doesn't impact login nodes
- Parallel creation possible
- Professional deployment

**Cons:**
- Queue wait time
- Delayed feedback
- Job log checking required

---

## 🧪 Testing Installation

### Quick Verification Script

```bash
# Run verification while environment is active
bash bin/verify_install_conda_install.sh env/

# Output:
# ================================================
# Conda ML Environment Verification
# ================================================
# 
# Environment: env/
# 
# Python & Core:
#   Python 3.12.1
#   ✓ NumPy
#   ✓ Pandas
# ... (more packages)
```

### Comprehensive Test Suite

```bash
# Option A: Run tests directly (after conda activate env/)
python tests/ml_env_test_script.py

# Option B: Submit SLURM test job
sbatch bin/test-conda-env_conda_install.sbatch

# Check results
tail -f logs/test-conda-env_conda_install-*.err
cat logs/test-conda-env_conda_install-*.out
```

### Test Coverage

The test suite validates:
- ✓ Python version and base packages (NumPy, Pandas, SciPy)
- ✓ Deep learning frameworks (PyTorch, TensorFlow, JAX)
- ✓ ML libraries (XGBoost, LightGBM, CatBoost, scikit-learn)
- ✓ Distributed computing (Dask, Ray)
- ✓ GPU support (cuDF, cuGraph - if installed)
- ✓ Data visualization (Matplotlib, Seaborn)

---

## 📚 File Reference

### Installation Scripts

#### `setup_install_conda_install.sh`
**Purpose:** Orchestrates entire installation process  
**Usage:** `bash bin/setup_install_conda_install.sh`  
**Environment Variables:**
- `PREFIX` - Project root (default: `.`)
- `ENV_PREFIX` - Environment location (default: `${PREFIX}/env`)
- `GENERATE_MODULEFILE` - Generate TCL module (optional, set to `1`)
- `MODULESHOME` - Module install path (required if generating modulefile)

**Output:** `conda_install.log`

---

#### `run_install_conda_install.sh`
**Purpose:** Core conda environment creator  
**Called by:** `setup_install_conda_install.sh`  
**Environment Variables:**
- `PREFIX` - Project root
- `ENV_PREFIX` - Target environment path

**Output:** `conda_install.log`

---

#### `verify_install_conda_install.sh`
**Purpose:** Post-installation validation  
**Usage:** `bash bin/verify_install_conda_install.sh env/`  
**Checks:**
- Environment directory exists
- Critical packages installed
- Python version correct
- Optional GPU packages

**Exit Codes:**
- `0` - All checks passed
- `1` - Some packages missing

---

### SLURM Job Scripts

#### `create-conda-env_conda_install.sbatch`
**Purpose:** Create environment on compute node via SLURM  
**Usage:** `sbatch bin/create-conda-env_conda_install.sbatch`  
**Default Configuration:**
- CPU: 4 cores per GPU
- Memory: 32 GB
- GPU: 1x V100
- Time: 2 hours
- Partition: `batch`

**Output:**
- `logs/conda-env-create-${JOB_ID}-slurm.out` - Standard output
- `logs/conda-env-create-${JOB_ID}-slurm.err` - Error messages
- `env/` - Created conda environment

---

#### `test-conda-env_conda_install.sbatch`
**Purpose:** Test environment on compute node  
**Usage:** `sbatch bin/test-conda-env_conda_install.sbatch`  
**Prerequisites:** Environment must exist at `./env`  
**Requirements:** Same as creation job or less

**Actions:**
1. Activates conda environment
2. Runs comprehensive test suite
3. Validates all major packages
4. Generates test report

**Output:**
- `logs/test-conda-env_conda_install-${JOB_ID}-slurm.out` - Test results
- `logs/test-conda-env_conda_install-${JOB_ID}-slurm.err` - Any errors

---

### Modulefile Generation

#### `generate_modulefile_conda_install.sh`
**Purpose:** Generate TCL modulefile for environment  
**Usage:**
```bash
export MODULESHOME=/sw/rl9g/modulefiles/applications
export VERSION=2026.01
bash bin/generate_modulefile_conda_install.sh
```

**Environment Variables:**
- `VERSION` - Version string (default: `2026.01`)
- `ENV_PREFIX` - Conda environment path (default: `.env`)
- `PREFIX` - Project root (default: `.`)
- `MODULESHOME` - Modulefiles directory (required)
- `PACKAGE` - Package name (default: `machine_learning`)

**Generated Module Path:** `${MODULESHOME}/${VERSION}/conda`

---

## 🔧 Advanced Usage

### Installing to Custom Location

```bash
# Create environment at custom path
export PREFIX=/scratch/${USER}/ml-project
export ENV_PREFIX=/scratch/${USER}/ml-project/conda-env

cd $PREFIX
bash bin/setup_install_conda_install.sh
```

### Using Alternative Conda

```bash
# With mamba (faster)
export CONDA_CMD=mamba
bash bin/setup_install_conda_install.sh

# With specific conda channel
export CONDARC=/path/to/condarc
bash bin/setup_install_conda_install.sh
```

### Batch Installation with Module File

```bash
# Create environment AND generate module in one command
export MODULESHOME=/sw/rl9g/modulefiles/applications
export GENERATE_MODULEFILE=1
export VERSION=2026.01

bash bin/setup_install_conda_install.sh
```

### Debugging Installation Issues

```bash
# View installation log
cat conda_install.log
tail -100 conda_install.log

# Run with verbose output
bash -x bin/run_install_conda_install.sh

# Check environment directory
ls -lah env/
du -sh env/
```

---

## 🚨 Troubleshooting

### Problem: "conda: command not found"
**Solution:**
```bash
source /ibex/user/${USER}/miniconda3/bin/activate
# OR
module load conda
```

### Problem: Environment creation stuck
**Solution:**
```bash
# Cancel stuck SLURM job
scancel ${JOB_ID}

# Check conda lock files
find env/ -name "*.lock" -delete

# Retry with --force flag
bash bin/setup_install_conda_install.sh
```

### Problem: "environment.yml not found"
**Solution:**
```bash
# Ensure you're in project root
pwd  # should be /ibex/user/barradd/ibex-machine-learning-modules
ls -la environment.yml

# Or specify PREFIX
export PREFIX=/path/to/project
bash bin/setup_install_conda_install.sh
```

### Problem: GPU packages not working
**Solution:**
```bash
# Test CUDA availability
python -c "import torch; print(torch.cuda.is_available())"

# Check cuDF
python -c "import cudf; print(cudf.__version__)"

# If issues, verify environment.yml includes GPU variants
grep -i cuda environment.yml
```

### Problem: Out of disk space
**Solution:**
```bash
# Check disk usage
du -sh env/
df -h

# Clean conda cache
conda clean --all --yes

# Use SLURM temp directory
export CONDA_PKGS_DIRS="${SLURM_TMPDIR}/.conda_cache"
```

---

## 📊 Performance Expectations

### Installation Time
- **Small environment** (core packages): 15-25 minutes
- **Medium environment** (standard ML stack): 25-40 minutes  
- **Large environment** (with GPU/RAPIDS): 40-60 minutes

### Disk Usage
- **Small environment**: 2-5 GB
- **Medium environment**: 5-10 GB
- **Large environment**: 10-20 GB

### Creation on Login Node
- Slower (competes with user activity)
- Not recommended for production
- Good for testing/development

### Creation on Compute Node (SLURM)
- Dedicated resources
- Faster (25-40% speedup possible)
- Best practice for clusters

---

## ✅ Checklist - Installation Complete

- [ ] environment.yml updated with required packages
- [ ] `bash bin/setup_install_conda_install.sh` executed successfully
- [ ] Or `sbatch bin/create-conda-env_conda_install.sbatch` job completed
- [ ] `conda activate env/` works
- [ ] `bash bin/verify_install_conda_install.sh env/` shows all checks passed
- [ ] `sbatch bin/test-conda-env_conda_install.sbatch` tests pass
- [ ] (Optional) `bash bin/generate_modulefile_conda_install.sh` created module
- [ ] (Optional) `module load machine_learning/2026.01/conda` loads module

---

## 📞 Getting Help

### Documentation Files
- [CONDA_SLURM_GUIDE.md](CONDA_SLURM_GUIDE.md) - SLURM-specific guide
- [CONDA_TESTING_GUIDE.md](CONDA_TESTING_GUIDE.md) - Testing & verification
- [CONDA_MODULEFILE_GUIDE.md](CONDA_MODULEFILE_GUIDE.md) - Module files guide
- [CONDA_TROUBLESHOOTING.md](CONDA_TROUBLESHOOTING.md) - Issue solutions

### Log Files
```bash
# Installation log
cat conda_install.log

# SLURM job logs (after submission)
cat logs/conda-env-create-*.err
cat logs/conda-env-create-*.out

# Test logs
cat logs/test-conda-env_conda_install-*.err
```

### Quick Info
```bash
# Environment info
conda info

# List packages
conda list

# Python version
python -c "import sys; print(sys.version)"

# Check GPU
python -c "import torch; print(torch.cuda.is_available())"
```

---

## 📌 Related Documentation

- [Singularity Container Guide](SINGULARITY_DEPLOYMENT.md) - Alternative container approach
- [Docker Build Guide](CONTAINER_BUILD.md) - Local Docker builds
- [Deployment Guide](DEPLOYMENT_GUIDE.md) - General HPC deployment
- [Quick Reference](QUICK_REFERENCE.md) - Common commands

---

**Last Updated:** February 24, 2026  
**Version:** 2026.01
