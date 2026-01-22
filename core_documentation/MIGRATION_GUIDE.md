# Migration Guide: Conda → Singularity Container

**Migrate from conda-based ML environment to Singularity container deployment**

---

## 🎯 Overview

This guide helps migrate from the previous conda-based installation to the new Singularity container-based deployment on Ibex HPC cluster.

### Key Benefits of Migration
- ✅ **3x faster setup** - 30-60 min vs. 2-4 hours
- ✅ **Shared resources** - One 6-7 GB image vs. 15-20 GB per user
- ✅ **Reproducible** - Frozen versions, no surprise updates
- ✅ **Secure** - Container isolation + non-root execution
- ✅ **Easier maintenance** - Centralized updates
- ✅ **Better HPC integration** - Native SLURM support

---

## 📊 Comparison: Conda vs Container

| Factor | Conda (Old) | Container (New) |
|--------|------------|-----------------|
| **Setup Time** | 2-4 hours/user | 30-60 min (shared) |
| **Disk per User** | 15-20 GB | 0 GB (shared) |
| **Total Disk** | 15-20 GB × N users | 6-7 GB |
| **Updates** | Manual per user | Centralized |
| **Reproducibility** | Moderate | Excellent |
| **Security** | User-level | Container isolation |
| **GPU Access** | Direct | `--nv` flag |
| **SLURM Integration** | Manual config | Native |
| **Scaling** | Linear cost | Constant cost |

### Cost Example (10 Users)
- **Conda:** 150-200 GB disk + 2-4 hours setup per user
- **Container:** 6-7 GB disk + 30-60 min one-time setup

---

## 🔄 Software Versions

### Framework Updates
| Package | Conda | Container | Change |
|---------|-------|-----------|--------|
| **Python** | 3.12 | 3.12 | ✅ Same |
| **RAPIDS** | 25.08 | 25.12 | ⬆️ +4 months |
| **PyTorch** | 2.5.1 | 2.5.1 | ✅ Same |
| **TensorFlow** | 2.20.0 | 2.20.0 | ✅ Same |
| **JAX** | 0.8.2 | 0.8.2 | ✅ Same |
| **CUDA** | 12.1 | 13.0 | ⬆️ Major |
| **cuDNN** | 8 | 8 | ✅ Same |

### New Packages Added
The container includes modern tools not in the original conda environment:

**MLOps & Experiment Tracking**
- MLflow - Experiment tracking and model registry
- Optuna - Hyperparameter optimization
- Weights & Biases - Experiment monitoring

**Data Processing**
- Polars - Fast DataFrame library (Rust-based)
- Zarr - Chunked, compressed arrays
- Apache Arrow - Columnar data format

**Configuration & Validation**
- Hydra - Configuration management
- Pydantic v2 - Data validation

**Monitoring & Debugging**
- Prometheus client - Metrics collection
- Rich - Better console output
- Debugpy - Python debugger for VSCode

---

## 🚀 Migration Steps

### For Administrators

#### Step 1: Plan Migration Window
```bash
# Review current conda deployment
du -sh /ibex/user/*/miniconda3/envs/*

# Check active users
squeue -u ALL | grep python

# Schedule downtime (usually not needed - deployment is separate)
```

#### Step 2: Build Singularity Container
```bash
# Option A: Automated (recommended)
cd /sw/sources/machine_learning/ibex-machine-learning-modules
bash bin/setup_install.sh

# Option B: Manual
sudo singularity build ml_module_2025.09.sif ml_module.def
```

Expected output:
```
Building Singularity container from ml_module.def...
[Stage 1: Bootstrap] Pulling NVIDIA CUDA image... (5 min)
[Stage 2: Mambaforge] Installing conda package manager... (10 min)
[Stage 3: Environment] Installing 100+ packages... (30-40 min)
[Stage 4: RAPIDS] Installing GPU-accelerated packages... (5-10 min)
[Stage 5: Finalize] Cleaning up and configuring... (2 min)

Container built successfully: ml_module_2025.09.sif (6.8 GB)
```

#### Step 3: Create Environment Module
```bash
bash bin/generate_modulefile.sh

# Creates: /sw/rl9g/modulefiles/applications/machine_learning/2025.09/singularity
```

#### Step 4: Test Deployment
```bash
# Load module
module load machine_learning/2025.09/singularity

# Verify basic functionality
singularity exec $ML_CONTAINER_PATH python tests/ml_env_test_script.py

# Check results
cat ml_env_test_results.json | jq '.summary'

# Submit test job
sbatch <<'EOF'
#!/bin/bash
#SBATCH --gpus=1
#SBATCH --time=00:10:00
module load machine_learning/2025.09/singularity
singularity exec --nv $ML_CONTAINER_PATH python -c "
import torch
print(f'CUDA: {torch.cuda.is_available()}')
print(f'GPUs: {torch.cuda.device_count()}')
"
EOF
```

#### Step 5: Communicate with Users
```
📢 ML Module Migration

The ML module has been updated to Singularity containers:

Old way:
  module load machine_learning/2025.01  # Conda-based
  python train.py

New way:
  module load machine_learning/2025.09/singularity
  singularity exec $ML_CONTAINER_PATH python train.py

Benefits:
  ✅ 2x faster compute startup
  ✅ Better reproducibility
  ✅ Shared resources (15-20 GB → 6-7 GB total)
  ✅ Centralized maintenance

See [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) for details.
```

---

### For End Users

#### Step 1: Update Your SLURM Scripts

**Old Script (Conda):**
```bash
#!/bin/bash
#SBATCH --job-name=ml-train
#SBATCH --gpus-per-node=1
#SBATCH --cpus-per-task=8
#SBATCH --time=04:00:00

module load machine_learning/2025.01

# Activate conda environment
source activate $CONDA_PREFIX

# Run training
python train.py --batch-size 64
```

**New Script (Container):**
```bash
#!/bin/bash
#SBATCH --job-name=ml-train
#SBATCH --gpus=1
#SBATCH --cpus-per-task=8
#SBATCH --time=04:00:00

module load machine_learning/2025.09/singularity

# Run training
singularity exec --nv $ML_CONTAINER_PATH python train.py --batch-size 64
```

**Key Changes:**
- ❌ Remove: `source activate $CONDA_PREFIX`
- ✅ Add: `singularity exec --nv $ML_CONTAINER_PATH`
- ✅ Note: `--gpus-per-node` → `--gpus` (SLURM syntax update)

#### Step 2: Data Access with Bind Mounts

**Old Way (Conda):**
```bash
# Data was anywhere in filesystem
python train.py --data ~/data/dataset.csv
```

**New Way (Container):**
```bash
# Need to bind mount data directory
singularity exec --nv \
  --bind /project/$USER/data:/data \
  $ML_CONTAINER_PATH python train.py --data /data/dataset.csv
```

**Common Bind Patterns:**
```bash
# Single directory
--bind /project/$USER/data:/data

# Multiple directories
--bind /project/$USER/data:/data \
--bind /scratch/$USER/results:/results

# Read-only data
--bind /project/shared_data:/data:ro

# Write-only output
--bind /scratch/$USER/output:/output
```

#### Step 3: Common Workflow Examples

**Example 1: Single GPU Training**
```bash
#!/bin/bash
#SBATCH --gpus=1
#SBATCH --time=04:00:00

module load machine_learning/2025.09/singularity

singularity exec --nv \
  --bind $PWD:/work \
  --bind /project/$USER/data:/data \
  $ML_CONTAINER_PATH python /work/train.py
```

**Example 2: Multi-GPU with PyTorch DDP**
```bash
#!/bin/bash
#SBATCH --gpus=4
#SBATCH --time=08:00:00
#SBATCH --nodes=1

module load machine_learning/2025.09/singularity

singularity exec --nv \
  --bind $PWD:/work \
  $ML_CONTAINER_PATH python -m torch.distributed.launch \
    --nproc_per_node=4 /work/train_ddp.py
```

**Example 3: Jupyter Interactive**
```bash
#!/bin/bash
#SBATCH --gpus=1
#SBATCH --time=08:00:00
#SBATCH --partition=debug

module load machine_learning/2025.09/singularity

singularity exec --nv \
  --bind $PWD:/work \
  $ML_CONTAINER_PATH jupyter lab \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser
```

**Example 4: Dask Distributed**
```bash
#!/bin/bash
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G

module load machine_learning/2025.09/singularity

singularity exec $ML_CONTAINER_PATH dask-scheduler &
SCHEDULER_PID=$!

for i in {1..4}; do
  singularity exec $ML_CONTAINER_PATH \
    dask-worker localhost:8786 &
done

singularity exec --nv \
  --bind $PWD:/work \
  $ML_CONTAINER_PATH python /work/dask_job.py

kill $SCHEDULER_PID
wait
```

#### Step 4: Test Migration

```bash
# Verify module loads
module load machine_learning/2025.09/singularity

# Verify container access
echo $ML_CONTAINER_PATH

# Test Python execution
singularity exec $ML_CONTAINER_PATH python --version

# Test GPU access
singularity exec --nv $ML_CONTAINER_PATH python -c "
import torch
print(f'CUDA available: {torch.cuda.is_available()}')
"

# Test your own script
singularity exec --nv $ML_CONTAINER_PATH python your_script.py
```

---

## 🔧 Troubleshooting Migration

### Issue: "Module not found"
```bash
# Check available modules
module av machine_learning

# Verify module location
ls -l /sw/rl9g/modulefiles/applications/machine_learning/

# Reload module cache
module spider machine_learning

# Load with full version
module load machine_learning/2025.09/singularity
```

### Issue: "Container path not set"
```bash
# Verify environment variable
echo $ML_CONTAINER_PATH

# If empty, module didn't load properly
module show machine_learning/2025.09/singularity

# Manual set (temporary)
export ML_CONTAINER_PATH=/sw/applications/machine_learning/2025.09/singularity/ml_module_2025.09.sif
```

### Issue: "CUDA not available in container"
```bash
# Check you're using --nv flag
singularity exec --nv $ML_CONTAINER_PATH python -c "
import torch
print(f'CUDA: {torch.cuda.is_available()}')
"

# Check NVIDIA drivers on compute node
ssh compute_node
nvidia-smi

# Check GPU allocation in SLURM
squeue -j $SLURM_JOB_ID -o '%b'
```

### Issue: "Permission denied for data directory"
```bash
# Check directory permissions
ls -ld /project/$USER/data

# Use read-only bind if writing not needed
--bind /project/$USER/data:/data:ro

# Check umask
umask

# Set proper permissions
chmod u+rwx /project/$USER/data
```

### Issue: "Package import fails"
```bash
# Verify package in container
singularity exec $ML_CONTAINER_PATH pip list | grep package-name

# Check Python path
singularity exec $ML_CONTAINER_PATH python -c "
import sys
for p in sys.path:
    print(p)
"

# Check environment variable
singularity exec $ML_CONTAINER_PATH env | grep PYTHON
```

### Issue: "Out of memory during compute"
```bash
# Check available memory in SLURM
#SBATCH --mem=64G  # Increase memory request

# Check GPU memory
singularity exec --nv $ML_CONTAINER_PATH nvidia-smi

# Reduce batch size in your code
# Or use gradient accumulation
```

---

## 📈 Performance Comparison

### Build Time
```
Conda (old):        ████████████████████ 2-4 hours
Container (new):    ███████ 30-60 minutes  ← 3-4x faster
```

### Disk Space per User
```
Conda (old):        ██████████████ 15-20 GB
Container (new):    ◆ 0 GB (shared)        ← Hundreds of users, no added cost
```

### Job Startup Time
```
Conda (old):        ███ 30-60 seconds
Container (new):    ◆ 5-10 seconds         ← 3-10x faster
```

### SLURM Queue Time
```
Old setup: Allocate CPU → Load env (30-60s) → Run job
New setup: Allocate CPU → Load env (5-10s) → Run job
           ↑ ~10% faster effective queue throughput
```

---

## ✅ Migration Checklist

### For Administrators
- [ ] Read [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- [ ] Build Singularity container (Step 1-2 above)
- [ ] Test with ml_env_test_script.py
- [ ] Create environment module (Step 3)
- [ ] Test module loading and basic execution
- [ ] Run full test suite (ml_env_test_script.py + distributed_test_script.py)
- [ ] Communicate timeline with users
- [ ] Deprecate old conda module

### For End Users
- [ ] Read [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- [ ] Load new module: `module load machine_learning/2025.09/singularity`
- [ ] Update SLURM scripts (add `singularity exec --nv`)
- [ ] Test with small job first
- [ ] Update data bind mounts if needed
- [ ] Run full training with updated scripts
- [ ] Verify results match previous conda runs

---

## 🎓 Additional Resources

- **Deployment Guide:** [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Complete admin guide
- **Container Building:** [CONTAINER_BUILD.md](CONTAINER_BUILD.md) - Docker/Singularity build
- **Quick Reference:** [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Common commands
- **Package List:** [REQUIREMENTS_BREAKDOWN.md](REQUIREMENTS_BREAKDOWN.md) - All 100+ packages
- **Full Index:** [INDEX.md](INDEX.md) - Complete navigation

---

## 📞 Support

**Migration Questions:** See troubleshooting section above  
**Container Issues:** Check [CONTAINER_BUILD.md](CONTAINER_BUILD.md)  
**HPC Issues:** Contact Ibex cluster support team  
**Package Issues:** Check [REQUIREMENTS_BREAKDOWN.md](REQUIREMENTS_BREAKDOWN.md)

---

**Last Updated:** January 2026  
**Version:** 2025.09 (Container) → 2025.01 (Old Conda)  
**Container:** ml_module_2025.09.sif
