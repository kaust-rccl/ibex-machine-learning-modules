# Quick Reference - ML Module Container

**Fast lookups for common tasks with the Ibex ML container**

---

## 🚀 Essential Commands

### Loading the Module
```bash
# Load the ML module
module load machine_learning/2025.09/singularity

# Check what's loaded
module list

# See module details
module show machine_learning/2025.09/singularity
```

### Running Python
```bash
# Run a Python script
singularity exec --nv $ML_CONTAINER_PATH python train.py

# Python one-liner
singularity exec --nv $ML_CONTAINER_PATH python -c "import torch; print(torch.cuda.is_available())"

# Interactive Python
singularity exec --nv $ML_CONTAINER_PATH python
```

### Interactive Shell
```bash
# Open shell inside container
singularity shell --nv $ML_CONTAINER_PATH

# With custom binds
singularity shell --nv \
  --bind /project/data:/data \
  --bind /scratch/$USER:/scratch \
  $ML_CONTAINER_PATH
```

---

## 📦 What's Installed

### Check Versions
```bash
# PyTorch
singularity exec $ML_CONTAINER_PATH python -c "import torch; print(torch.__version__)"

# TensorFlow
singularity exec $ML_CONTAINER_PATH python -c "import tensorflow as tf; print(tf.__version__)"

# RAPIDS cuDF
singularity exec $ML_CONTAINER_PATH python -c "import cudf; print(cudf.__version__)"

# All package versions
singularity exec $ML_CONTAINER_PATH pip list
singularity exec $ML_CONTAINER_PATH conda list
```

### GPU Check
```bash
# NVIDIA GPU status
singularity exec --nv $ML_CONTAINER_PATH nvidia-smi

# CUDA availability in PyTorch
singularity exec --nv $ML_CONTAINER_PATH python -c "import torch; print(f'CUDA: {torch.cuda.is_available()}, GPUs: {torch.cuda.device_count()}')"

# TensorFlow GPU check
singularity exec --nv $ML_CONTAINER_PATH python -c "import tensorflow as tf; print(f'GPUs: {len(tf.config.list_physical_devices(\"GPU\"))}')"
```

---

## 🎯 SLURM Job Patterns

### Single-GPU Training
```bash
#!/bin/bash
#SBATCH --job-name=ml-train
#SBATCH --time=04:00:00
#SBATCH --gpus=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --partition=batch

module load machine_learning/2025.09/singularity

singularity exec --nv \
  --bind $PWD:/work \
  --bind /project/$USER/data:/data \
  $ML_CONTAINER_PATH python /work/train.py
```

### Multi-GPU (Single Node)
```bash
#!/bin/bash
#SBATCH --job-name=ml-multi-gpu
#SBATCH --time=08:00:00
#SBATCH --gpus=4
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --partition=batch

module load machine_learning/2025.09/singularity

# PyTorch DDP
singularity exec --nv \
  --bind $PWD:/work \
  $ML_CONTAINER_PATH python -m torch.distributed.launch \
    --nproc_per_node=4 /work/train_ddp.py

# Or TensorFlow MirroredStrategy (auto-detects GPUs)
singularity exec --nv \
  --bind $PWD:/work \
  $ML_CONTAINER_PATH python /work/train_tf.py
```

### Jupyter Lab
```bash
#!/bin/bash
#SBATCH --job-name=jupyter
#SBATCH --time=08:00:00
#SBATCH --gpus=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --partition=debug

module load machine_learning/2025.09/singularity

singularity exec --nv \
  --bind $PWD:/work \
  $ML_CONTAINER_PATH jupyter lab \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser \
    --NotebookApp.token=''
```

### Dask Distributed
```bash
#!/bin/bash
#SBATCH --job-name=dask-cluster
#SBATCH --time=04:00:00
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G

module load machine_learning/2025.09/singularity

# Start Dask scheduler
singularity exec --nv $ML_CONTAINER_PATH dask-scheduler &
SCHEDULER_PID=$!

# Start workers
for i in {1..4}; do
  singularity exec --nv $ML_CONTAINER_PATH dask-worker localhost:8786 &
done

# Run your script
singularity exec --nv \
  --bind $PWD:/work \
  $ML_CONTAINER_PATH python /work/dask_job.py

# Cleanup
kill $SCHEDULER_PID
```

---

## 🔧 Common Workflows

### Data Processing with RAPIDS
```bash
# Interactive
singularity exec --nv \
  --bind /project/$USER/data:/data \
  $ML_CONTAINER_PATH python

# Then in Python:
import cudf
df = cudf.read_csv('/data/large_file.csv')
df_filtered = df[df['value'] > 100]
df_filtered.to_parquet('/data/output.parquet')
```

### Model Training with PyTorch
```python
# train.py
import torch
import torch.nn as nn

device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
model = nn.Sequential(
    nn.Linear(784, 256),
    nn.ReLU(),
    nn.Linear(256, 10)
).to(device)

# Your training loop...
```

```bash
# Run
singularity exec --nv $ML_CONTAINER_PATH python train.py
```

### Hyperparameter Optimization with Optuna
```python
# hpo.py
import optuna
import lightgbm as lgb

def objective(trial):
    param = {
        'objective': 'binary',
        'metric': 'binary_logloss',
        'num_leaves': trial.suggest_int('num_leaves', 20, 50),
        'learning_rate': trial.suggest_float('learning_rate', 0.01, 0.1),
    }
    # Your training code...
    return accuracy

study = optuna.create_study(direction='maximize')
study.optimize(objective, n_trials=100)
```

```bash
# Run
singularity exec --nv $ML_CONTAINER_PATH python hpo.py
```

### Experiment Tracking with MLflow
```python
# experiment.py
import mlflow

mlflow.set_experiment("my-experiment")

with mlflow.start_run():
    mlflow.log_param("learning_rate", 0.01)
    mlflow.log_param("batch_size", 32)
    
    # Training...
    accuracy = 0.95
    
    mlflow.log_metric("accuracy", accuracy)
    mlflow.pytorch.log_model(model, "model")
```

```bash
# Run training
singularity exec --nv $ML_CONTAINER_PATH python experiment.py

# View UI
singularity exec $ML_CONTAINER_PATH mlflow ui --host 0.0.0.0
```

---

## 🧪 Testing & Validation

### Run Test Suite
```bash
# Environment tests
singularity exec --nv $ML_CONTAINER_PATH python tests/ml_env_test_script.py
cat ml_env_test_results.json

# Distributed tests
singularity exec --nv $ML_CONTAINER_PATH python tests/distributed_test_script.py
cat distributed_test_results.json
```

### Quick Smoke Tests
```bash
# Test all frameworks
singularity exec --nv $ML_CONTAINER_PATH python -c "
import torch, tensorflow as tf, jax, cudf, lightgbm
print('✅ All frameworks imported successfully')
print(f'CUDA: {torch.cuda.is_available()}')
print(f'GPUs: {torch.cuda.device_count()}')
"
```

---

## 🛠️ Development & Debugging

### Install Additional Packages (Temporary)
```bash
# Only persists during session
singularity exec --nv $ML_CONTAINER_PATH pip install --user your-package

# Then use
singularity exec --nv $ML_CONTAINER_PATH python -c "import your_package"
```

### Debug Container Issues
```bash
# Check container info
singularity inspect $ML_CONTAINER_PATH

# Verbose execution
singularity -v exec --nv $ML_CONTAINER_PATH python script.py

# Check environment variables
singularity exec $ML_CONTAINER_PATH env | grep -E 'CUDA|PATH|LD_LIBRARY'
```

### Profile GPU Usage
```bash
# Monitor GPU while training
watch -n 1 nvidia-smi

# In separate terminal, run:
singularity exec --nv $ML_CONTAINER_PATH python train.py
```

---

## 📁 Data Management

### Bind Mounts (Read/Write)
```bash
# Bind project directory
singularity exec --nv \
  --bind /project/$USER:/project \
  $ML_CONTAINER_PATH python train.py

# Multiple binds
singularity exec --nv \
  --bind /scratch/$USER:/scratch \
  --bind /project/$USER/data:/data:ro \
  --bind /project/$USER/results:/results \
  $ML_CONTAINER_PATH python process.py
```

### Working with Large Datasets
```bash
# Use scratch space for temporary files
export TMPDIR=/scratch/$USER/tmp
mkdir -p $TMPDIR

singularity exec --nv \
  --bind /scratch/$USER:/scratch \
  --env TMPDIR=$TMPDIR \
  $ML_CONTAINER_PATH python train.py
```

---

## 🔍 Monitoring & Logging

### Capture Logs
```bash
# Redirect stdout/stderr
singularity exec --nv $ML_CONTAINER_PATH python train.py \
  > train.log 2>&1

# Or in SLURM
#SBATCH --output=slurm-%j.out
#SBATCH --error=slurm-%j.err
```

### Monitor Resources
```bash
# CPU/Memory usage
top -u $USER

# GPU usage
nvidia-smi dmon -s pucvmet -d 1

# In Python script
import psutil
import GPUtil
print(f"CPU: {psutil.cpu_percent()}%")
print(f"RAM: {psutil.virtual_memory().percent}%")
gpus = GPUtil.getGPUs()
for gpu in gpus:
    print(f"GPU {gpu.id}: {gpu.load*100}%, {gpu.memoryUsed}MB/{gpu.memoryTotal}MB")
```

---

## ⚡ Performance Tips

### Optimize Data Loading
```python
# PyTorch DataLoader
from torch.utils.data import DataLoader

loader = DataLoader(
    dataset,
    batch_size=128,
    num_workers=8,      # Match SLURM cpus-per-task
    pin_memory=True,    # Faster GPU transfer
    persistent_workers=True
)
```

### RAPIDS GPU Memory Management
```python
import cudf
import rmm

# Set memory pool
rmm.reinitialize(
    pool_allocator=True,
    initial_pool_size=8 << 30,  # 8 GB
)

# Process data
df = cudf.read_parquet('large_file.parquet')
```

### Dask Configuration
```python
from dask.distributed import Client, LocalCluster

cluster = LocalCluster(
    n_workers=4,
    threads_per_worker=2,
    memory_limit='32GB'
)
client = Client(cluster)
```

---

## 🐛 Troubleshooting

### Common Issues

**"CUDA not available"**
```bash
# Check you're using --nv flag
singularity exec --nv $ML_CONTAINER_PATH python -c "import torch; print(torch.cuda.is_available())"

# Check GPU allocation in SLURM
squeue -u $USER -o "%.18i %.9P %.30j %.8T %.10M %.6D %b"
```

**"Module not found"**
```bash
# Verify package is installed
singularity exec $ML_CONTAINER_PATH pip list | grep package-name

# Check Python path
singularity exec $ML_CONTAINER_PATH python -c "import sys; print(sys.path)"
```

**"Permission denied"**
```bash
# Check bind mount permissions
ls -ld /project/$USER

# Try read-only bind
singularity exec --nv --bind /project/$USER:/data:ro $ML_CONTAINER_PATH python script.py
```

**"Out of memory"**
```bash
# Check GPU memory
singularity exec --nv $ML_CONTAINER_PATH nvidia-smi

# Reduce batch size or use gradient accumulation
# Request more memory in SLURM
#SBATCH --mem=64G
```

---

## 📚 Additional Resources

- **Full Documentation:** [INDEX.md](INDEX.md)
- **Deployment Guide:** [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **Container Building:** [CONTAINER_BUILD.md](CONTAINER_BUILD.md)
- **Package List:** [REQUIREMENTS_BREAKDOWN.md](REQUIREMENTS_BREAKDOWN.md)
- **Migration Guide:** [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)

---

## 🎓 Learning Resources

### Singularity/Apptainer
- Official docs: https://apptainer.org/docs/
- HPC containers: https://carpentries-incubator.github.io/singularity-introduction/

### SLURM
- Quick start: https://slurm.schedmd.com/quickstart.html
- GPU jobs: https://slurm.schedmd.com/gres.html

### RAPIDS
- Getting started: https://rapids.ai/start.html
- cuDF docs: https://docs.rapids.ai/api/cudf/stable/

### PyTorch Distributed
- DDP tutorial: https://pytorch.org/tutorials/beginner/ddp_tutorial.html

### TensorFlow Distributed
- Strategy guide: https://www.tensorflow.org/guide/distributed_training

---

**Last Updated:** January 2026  
**Version:** 2025.09  
**Container:** ml_module_2025.09.sif
