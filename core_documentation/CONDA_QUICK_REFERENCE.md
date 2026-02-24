# Conda Installation - Quick Reference

**One-page cheat sheet for conda ML environment installation and usage**

---

## 🚀 30-Second Start

```bash
cd /ibex/user/barradd/ibex-machine-learning-modules

# Option 1: Local (quick test)
bash bin/setup_install_conda_install.sh

# Option 2: SLURM (production)
sbatch bin/create-conda-env_conda_install.sbatch

# Activate & use
conda activate env/
python your_script.py
```

---

## 📋 File Overview

| File | Purpose | When to Use |
|------|---------|------------|
| `setup_install_conda_install.sh` | Orchestrator | Direct installation |
| `run_install_conda_install.sh` | Core installer | Called by setup |
| `verify_install_conda_install.sh` | Quick check | Post-install validation |
| `create-conda-env_conda_install.sbatch` | SLURM creation | Production setup |
| `test-conda-env_conda_install.sbatch` | SLURM testing | Verification job |
| `generate_modulefile_conda_install.sh` | Module generator | HPC cluster use |

---

## 🎯 Common Workflows

### Workflow 1: Create → Test → Use (Direct)
```bash
# Create
bash bin/setup_install_conda_install.sh

# Test
bash bin/verify_install_conda_install.sh env/

# Use
conda activate env/
python script.py
```

### Workflow 2: Create → Test via SLURM
```bash
# Create on compute node
sbatch bin/create-conda-env_conda_install.sbatch
# Wait for job to finish

# Test on compute node
sbatch bin/test-conda-env_conda_install.sbatch
# Check logs: cat logs/test-conda-env_conda_install-*.out
```

### Workflow 3: Create with Module File
```bash
# Create environment
bash bin/setup_install_conda_install.sh

# Generate module
export MODULESHOME=/sw/rl9g/modulefiles/applications
bash bin/generate_modulefile_conda_install.sh

# Use with module
module load machine_learning/2026.01/conda
python script.py
```

---

## 🔧 Customize Installation

### Environment Configuration
```bash
# Edit environment.yml before installing
vim environment.yml

# Then run setup
bash bin/setup_install_conda_install.sh
```

### Custom Paths
```bash
export PREFIX=/scratch/${USER}/ml-project
export ENV_PREFIX=/scratch/${USER}/ml-env
bash bin/setup_install_conda_install.sh
```

### SLURM Resources
```bash
# Edit SBATCH directives before submitting
vim bin/create-conda-env_conda_install.sbatch

# Common edits:
#SBATCH --time=HH:MM:SS       # Increase time if needed
#SBATCH --mem=XXG             # Adjust memory
#SBATCH --gpus-per-node=N     # GPU count
sbatch bin/create-conda-env_conda_install.sbatch
```

---

## ✅ Verification Steps

**Quick Check (1 min):**
```bash
conda activate env/
python -c "import torch, tensorflow; print('OK')"
```

**Standard Check (5 min):**
```bash
bash bin/verify_install_conda_install.sh env/
```

**Full Test (20 min):**
```bash
sbatch bin/test-conda-env_conda_install.sbatch
tail logs/test-*.out
```

---

## 📊 Command Reference

### Activation
```bash
conda activate /path/to/env        # Direct path
conda activate env/                # Relative path
module load machine_learning/...   # With module file
```

### Status
```bash
conda list                          # Installed packages
conda info                          # Environment info
python -c "import torch; print(torch.__version__)"  # Framework versions
```

### GPU Check
```bash
nvidia-smi                          # GPU hardware
python -c "import torch; print(torch.cuda.is_available())"  # PyTorch
python -c "import cudf; print('cuDF OK')"  # cuDF
```

### Cleanup
```bash
conda clean --all --yes             # Clear cache
conda env remove --prefix ./env     # Delete environment
```

---

## 🚨 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| conda: command not found | `source /ibex/user/${USER}/miniconda3/bin/activate` |
| env not created | Check `conda_install.log` for errors |
| Import errors | `conda list` to verify package |
| GPU not found | `nvidia-smi` to check hardware |
| SLURM job timeout | Increase `#SBATCH --time=XX:XX:XX` |
| Out of disk | Run on node with `$SLURM_TMPDIR` |

---

## 📁 File Locations

```
Project Root: /ibex/user/barradd/ibex-machine-learning-modules/

Installation Scripts (bin/):
  ├── setup_install_conda_install.sh
  ├── run_install_conda_install.sh
  ├── verify_install_conda_install.sh
  ├── create-conda-env_conda_install.sbatch
  ├── test-conda-env_conda_install.sbatch
  └── generate_modulefile_conda_install.sh

Documentation (core_documentation/):
  ├── CONDA_INSTALLATION_GUIDE.md
  ├── CONDA_SLURM_GUIDE.md
  ├── CONDA_TESTING_GUIDE.md
  ├── CONDA_MODULEFILE_GUIDE.md
  └── CONDA_QUICK_REFERENCE.md (this file)

Environment:
  └── env/  (created after installation)

Logs:
  ├── conda_install.log
  └── logs/conda-env-create-*.out
```

---

## 🎓 Documentation Map

| Guide | Best For |
|-------|----------|
| **CONDA_INSTALLATION_GUIDE.md** | Direct setup, using conda activate |
| **CONDA_SLURM_GUIDE.md** | Cluster jobs, batch processing |
| **CONDA_TESTING_GUIDE.md** | Validating environment, fixing issues |
| **CONDA_MODULEFILE_GUIDE.md** | HPC module system, `module load` |
| **CONDA_QUICK_REFERENCE.md** | One-page cheat sheet (this file) |

---

## 💡 Pro Tips

1. **Use module files on HPC** - Cleaner than conda activate
2. **Test via SLURM** - Matches production environment
3. **Check logs early** - Find issues before full run
4. **Set --time conservatively** - Cheaper than out-of-time jobs
5. **Batch similar jobs** - Use job arrays for efficiency
6. **Monitor GPU** - `nvidia-smi` while running jobs
7. **Keep environment.yml** - Easy to rebuild if needed

---

## 🔗 Common Environment Variables

For scripting and advanced usage:

```bash
PREFIX                  # Project root
ENV_PREFIX              # Conda environment path
CONDA_DEFAULT_ENV       # Current environment name
MODULESHOME             # Module files directory
VERSION                 # Version string (2026.01)
PACKAGE                 # Package name (machine_learning)
```

Example:
```bash
export PREFIX=$PWD
export ENV_PREFIX=$PREFIX/env
export MODULESHOME=/sw/rl9g/modulefiles/applications
export VERSION=2026.01
bash bin/generate_modulefile_conda_install.sh
```

---

## 📞 Getting More Help

```bash
# View script help
head -20 bin/setup_install_conda_install.sh

# Read full docs
cat core_documentation/CONDA_INSTALLATION_GUIDE.md

# Check installation log
less conda_install.log

# View SLURM job logs
cat logs/conda-env-create-*.err
```

---

## ✨ What Gets Installed

From `environment.yml`:

**Core Data Science:**
- NumPy, Pandas, SciPy, scikit-learn

**Deep Learning:**
- PyTorch (latest with CUDA support)
- TensorFlow (latest)
- JAX with CUDA support

**ML Libraries:**
- XGBoost, LightGBM, CatBoost

**GPU Computing:**
- RAPIDS (cuDF, cuML, cuGraph)
- CUDA 12.2+

**Distributed Computing:**
- Dask, Ray

**Jupyter:**
- Jupyter Lab, IPython

See `environment.yml` for complete list.

---

## 🎯 Next Steps

1. **Customize environment.yml** with your packages
2. **Run installation** via direct or SLURM method
3. **Test the environment** with verification scripts
4. **Create module file** if using HPC cluster
5. **Launch your workload** using job scripts

---

**Version:** 2026.01  
**Last Updated:** February 24, 2026  
**Quick Links:** [Installation](CONDA_INSTALLATION_GUIDE.md) | [SLURM](CONDA_SLURM_GUIDE.md) | [Testing](CONDA_TESTING_GUIDE.md) | [Modules](CONDA_MODULEFILE_GUIDE.md)
