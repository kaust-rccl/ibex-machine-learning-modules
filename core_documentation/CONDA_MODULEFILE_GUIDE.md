# Conda Module File Guide

**Guide for generating and using TCL module files with conda ML environments**

---

## 📋 Overview

Module files are TCL scripts that manage environment setup on HPC clusters. They automatically set environment variables, paths, and aliases when loaded with `module load`.

### Why Use Module Files?

**Module File Benefits:**
- ✓ **Centralized Management:** Single point of control for environment
- ✓ **Clean Shell:** Automatic cleanup on module unload
- ✓ **Versioning:** Multiple versions side-by-side
- ✓ **Documentation:** Built-in help information
- ✓ **Easy Switching:** `module load` vs `conda activate`
- ✓ **Cluster Integration:** Works with all HPC tools

**Conda Environment vs Module File:**
```
Conda Activate:          module load:
$ conda activate env/    $ module load machine_learning/2026.01/conda
$ python script.py       $ python script.py
$ conda deactivate       $ module unload machine_learning
```

---

## 🚀 Quick Start: Generate Your Module File

### Step 1: Create Conda Environment
```bash
cd /ibex/user/barradd/ibex-machine-learning-modules
bash bin/setup_install_conda_install.sh
# or
sbatch bin/create-conda-env_conda_install.sbatch
```

### Step 2: Generate Module File
```bash
# Set required variables
export MODULESHOME=/sw/rl9g/modulefiles/applications
export VERSION=2026.01
export PREFIX=$PWD

# Generate the module file
bash bin/generate_modulefile_conda_install.sh

# Expected output:
# [INFO] Generating conda modulefile...
# [INFO] Environment: ./env
# [INFO] ✓ Modulefile generated successfully
# [INFO] Location: /sw/rl9g/modulefiles/applications/2026.01/conda
```

### Step 3: Load and Use
```bash
# Load the module
module load machine_learning/2026.01/conda

# Verify it's loaded
echo $ML_ENV_PREFIX
echo $ML_PYTHON

# Use Python directly
$ML_PYTHON --version
python script.py
jupyter lab

# Unload when done
module unload machine_learning
```

---

## 📝 Module File Contents

### Generated Module Structure
```tcl
#%Module 1.0 -*- tcl -*-
#
# Module for machine learning package (Conda environment)
#

set name            machine_learning
set version         2026.01
set env_prefix      /ibex/user/barradd/ibex-machine-learning-modules/env
set stack           gpu
```

### Environment Variables Set by Module

| Variable | Value | Purpose |
|----------|-------|---------|
| `ML_ENV_PREFIX` | `/path/to/env` | Conda environment path |
| `CONDA_DEFAULT_ENV` | `/path/to/env` | Conda's default environment |
| `ML_PYTHON` | `/path/to/env/bin/python` | Python executable |
| `ML_PIP` | `/path/to/env/bin/pip` | Pip package manager |
| `ML_JUPYTER` | `/path/to/env/bin/jupyter` | Jupyter executable |
| `CUDA_VISIBLE_DEVICES` | `0` | GPU access (default) |

### Path Modifications

The module prepends these directories to your PATH:
```bash
PATH: /path/to/env/bin:${PATH}
LD_LIBRARY_PATH: /path/to/env/lib:${LD_LIBRARY_PATH}
PYTHONPATH: /path/to/env/lib/python*/site-packages:${PYTHONPATH}
```

This ensures conda's Python and libraries take precedence.

---

## 🔧 Customization

### Customize Module File Parameters

Before generating, set these variables:

```bash
# Version string
export VERSION=2026.01

# Conda environment path
export ENV_PREFIX=/path/to/your/env

# Project root  
export PREFIX=/path/to/project

# Module file installation directory
export MODULESHOME=/sw/rl9g/modulefiles/applications

# Package name (for `module load` command)
export PACKAGE=machine_learning

# Then generate
bash bin/generate_modulefile_conda_install.sh
```

### Edit Generated Module File

After generation, you can manually edit the module file:

```bash
# Edit the generated module
vim /sw/rl9g/modulefiles/applications/2026.01/conda

# Example: Add custom variables
setenv MY_DATA_PATH /scratch/data
setenv ML_MODEL_PATH /sw/models

# Reload module after edit
module unload machine_learning
module load machine_learning

# Verify changes
printenv ML_MODEL_PATH
```

### Add to Startup Script

Make the module load automatically:

```bash
# Add to your ~/.bashrc or job script
module load machine_learning/2026.01/conda

# Now ML tools are available
python script.py
```

---

## 🎯 Using Module Files in SLURM Jobs

### Example 1: Simple Job with Module

```bash
#!/bin/bash
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --gpus-per-node=1
#SBATCH --job-name=ml-job

# Load the ML module
module load machine_learning/2026.01/conda

# Run Python script
python train_model.py

# Use convenience variables
$ML_JUPYTER lab --ip=0.0.0.0
```

### Example 2: Multiple Framework Testing

```bash
#!/bin/bash
#SBATCH --time=00:30:00
#SBATCH --gpus-per-node=1

module load machine_learning/2026.01/conda

# Test PyTorch
$ML_PYTHON -c "import torch; print(f'PyTorch: {torch.__version__}')"

# Test TensorFlow  
$ML_PYTHON -c "import tensorflow; print(f'TensorFlow: {tensorflow.__version__}')"

# Test JAX
$ML_PYTHON -c "import jax; print(f'JAX: {jax.__version__}')"

# Run full test suite
module load ml_env_test_script.py
```

### Example 3: Distributed Training

```bash
#!/bin/bash
#SBATCH --time=02:00:00
#SBATCH --nodes=2
#SBATCH --tasks-per-node=4
#SBATCH --gpus-per-node=1
#SBATCH --job-name=distributed-ml

module load machine_learning/2026.01/conda

# Set up distributed training
export MASTER_ADDR=$(scontrol show hostname $SLURM_NODELIST | head -n1)
export MASTER_PORT=29500
export RANK=$SLURM_PROCID
export WORLD_SIZE=$SLURM_NPROCS

# Run distributed script
srun $ML_PYTHON train_distributed.py
```

---

## 🔍 Module Management

### View Available Modules

```bash
# List all available ML modules
module avail machine_learning

# Output:
# machine_learning/2026.01/conda
# machine_learning/2026.01/singularity
# machine_learning/2025.12/singularity
```

### Check Currently Loaded

```bash
# Show loaded modules
module list

# Show ML module details
module show machine_learning/2026.01/conda
```

### Module Help

```bash
# View module help (added automatically)
module help machine_learning/2026.01/conda

# Output:
# ----------- Module Specific Help for 'machine_learning/2026.01/conda' -----------
# 
# Loading information:
# Environment: /path/to/env
# Python: /path/to/env/bin/python
# Jupyter: /path/to/env/bin/jupyter lab
```

---

## 📊 Comparison: Module File vs Direct Conda

### Direct Conda Method

```bash
# Activation
source /ibex/user/${USER}/miniconda3/bin/activate
conda activate /ibex/user/barradd/ibex-machine-learning-modules/env

# Python access
python script.py

# Deactivation
conda deactivate
```

**Pros:**
- Lightweight
- Direct control
- Familiar to conda users

**Cons:**
- Manual activation required
- Requires source command
- Not ideal for job scripts

### Module File Method

```bash
# Loading
module load machine_learning/2026.01/conda

# Python access  
python script.py

# Unloading
module unload machine_learning
```

**Pros:**
- Single `module load` command
- Automatic PATH management
- Clean deactivation
- HPC cluster standard
- Easier in job scripts

**Cons:**
- Requires module infrastructure
- Less familiar to conda users
- Additional setup required

---

## 🚨 Troubleshooting Module Files

### Problem: "Module not found"
**Solution:**
```bash
# Ensure module path is set
module use /sw/rl9g/modulefiles/applications

# Verify module file exists
ls -la /sw/rl9g/modulefiles/applications/2026.01/conda

# Reload module database
module purge
module load machine_learning/2026.01/conda
```

### Problem: "Python command not found" after module load
**Solution:**
```bash
# Verify module loaded
module list

# Check PATH
echo $PATH | tr ':' '\n' | head -5

# Test Python directly
$ML_PYTHON --version

# If still not working, check shell
echo $SHELL
```

### Problem: Environment variables not set
**Solution:**
```bash
# Check what module sets
module show machine_learning/2026.01/conda

# Verify after loading
echo $ML_ENV_PREFIX
echo $ML_PYTHON
echo $CUDA_VISIBLE_DEVICES

# If missing, regenerate module file
bash bin/generate_modulefile_conda_install.sh
```

### Problem: GPU not available after module load
**Solution:**
```bash
# Check CUDA setting
echo $CUDA_VISIBLE_DEVICES

# Verify GPU physically present
nvidia-smi

# Check CUDA installation in environment
$ML_PYTHON -c "import torch; print(torch.cuda.is_available())"

# If issues, edit module file and adjust CUDA settings
vim /sw/rl9g/modulefiles/applications/2026.01/conda
```

---

## 🔄 Version Management

### Managing Multiple Versions

```bash
# Create different conda environments
bash bin/setup_install_conda_install.sh  # Creates ./env

# Generate module for version 2026.01
export VERSION=2026.01
bash bin/generate_modulefile_conda_install.sh

# Generate module for version 2026.02 (different env)
export VERSION=2026.02
export ENV_PREFIX=/path/to/another/env
bash bin/generate_modulefile_conda_install.sh
```

### Using Different Versions

```bash
# Load specific version
module load machine_learning/2026.01/conda
$ML_PYTHON --version

# Switch versions
module unload machine_learning
module load machine_learning/2026.02/conda
$ML_PYTHON --version

# Parallel usage is NOT recommended with module load
# Use conda activate instead for parallel environments
```

---

## 📚 Advanced Topics

### Custom Module Templates

To customize module generation, edit `bin/generate_modulefile_conda_install.sh`:

```bash
# Add custom variables
setenv MY_PROJECT_ROOT /path/to/project
setenv MY_DATA_PATH /scratch/data

# Add aliases
alias run-training '$ML_PYTHON /path/to/training.py'
alias run-inference '$ML_PYTHON /path/to/inference.py'

# Add conflict rules (prevent loading with others)
conflict machine_learning/*/singularity
```

### Module Hierarchy

For larger systems, organize modules hierarchically:

```
/sw/rl9g/modulefiles/
├── applications/
│   └── machine_learning/
│       ├── 2026.01/conda
│       ├── 2026.02/conda
│       └── 2026.01/singularity
└── tools/
    └── cuda/
        └── 13.0
```

### Module Dependencies

If your environment depends on other modules:

```tcl
# In generated module file
prereq cuda/13.0
prereq gcc/11.0

# When loading, dependencies load automatically
```

---

## ✅ Best Practices

1. **Use Descriptive Names:** `module load machine_learning/2026.01/conda`
2. **Document Versions:** Include changelog in module comments
3. **Test After Generation:** `module load` and verify all variables
4. **Version Control:** Keep modulefiles in git with configurations
5. **Document Dependencies:** List required modules in comments
6. **Use Conventions:** Follow your cluster's module naming scheme
7. **Central Deployment:** Keep modulefiles on shared storage
8. **Regular Updates:** Regenerate when environment changes

---

## 📞 Support & References

### Documentation
- [CONDA_INSTALLATION_GUIDE.md](CONDA_INSTALLATION_GUIDE.md) - Installation steps
- [CONDA_SLURM_GUIDE.md](CONDA_SLURM_GUIDE.md) - SLURM-specific guide
- [CONDA_TESTING_GUIDE.md](CONDA_TESTING_GUIDE.md) - Testing procedures

### Command Reference
```bash
# Generate modulefile
bash bin/generate_modulefile_conda_install.sh

# Test module loading
module load machine_learning/2026.01/conda
module list
module unload machine_learning

# Edit module file
vim /sw/rl9g/modulefiles/applications/2026.01/conda
```

---

**Last Updated:** February 24, 2026  
**Version:** 2026.01
