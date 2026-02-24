#!/bin/bash
#SBATCH --time=01:00:00
#SBATCH --gpus-per-node=v100:1
#SBATCH --cpus-per-gpu=6
#SBATCH --mem=32G
#SBATCH --partition=batch
#SBATCH --job-name=test-ml-container
#SBATCH --mail-type=ALL
#SBATCH --output=bin/%x-%j-slurm.out
#SBATCH --error=bin/%x-%j-slurm.err

# ==============================================================================
# SLURM job script to test the Singularity ML module container
# ==============================================================================

set -e

echo "========================================"
echo "ML Container Test Job"
echo "========================================"
echo "Job ID: $SLURM_JOB_ID"
echo "Hostname: $(hostname)"
echo "Date: $(date)"
echo "Working directory: $PWD"
echo ""

# Configuration
PROJECT_DIR="$PWD"
CONTAINER_IMAGE="$PROJECT_DIR/ml_module_v1.0.sif"
TEST_SCRIPT="$PROJECT_DIR/bin/ml_env_test_script.py"

# Check if container exists
if [ ! -f "$CONTAINER_IMAGE" ]; then
    echo "ERROR: Container image not found: $CONTAINER_IMAGE"
    echo "Please build the container first using: sudo ./bin/build-singularity-container.sh"
    exit 1
fi

# Bind mounts for the container
BIND_MOUNTS="--bind $PROJECT_DIR:/work"
BIND_MOUNTS="$BIND_MOUNTS --bind $SLURM_TMPDIR:/tmp"
BIND_MOUNTS="$BIND_MOUNTS --bind /ibex/user/$USER:/ibex/user/$USER"

echo "Container image: $CONTAINER_IMAGE"
echo "Bind mounts: $BIND_MOUNTS"
echo ""

# Display container information
echo "========================================"
echo "Container Information"
echo "========================================"
singularity inspect "$CONTAINER_IMAGE"
echo ""

# Test 1: Basic GPU availability
echo "========================================"
echo "Test 1: GPU Detection"
echo "========================================"
singularity exec --nv $BIND_MOUNTS "$CONTAINER_IMAGE" nvidia-smi
echo ""

# Test 2: Python and framework versions
echo "========================================"
echo "Test 2: Framework Versions"
echo "========================================"
singularity exec --nv $BIND_MOUNTS "$CONTAINER_IMAGE" python -c "
import sys
import torch
import tensorflow as tf
import jax
import cudf
import ray

print(f'Python version: {sys.version}')
print(f'PyTorch version: {torch.__version__}')
print(f'PyTorch CUDA available: {torch.cuda.is_available()}')
print(f'TensorFlow version: {tf.__version__}')
print(f'TensorFlow GPU devices: {len(tf.config.list_physical_devices(\"GPU\"))}')
print(f'JAX version: {jax.__version__}')
print(f'JAX devices: {jax.devices()}')
print(f'RAPIDS cuDF version: {cudf.__version__}')
print(f'Ray version: {ray.__version__}')
"
echo ""

# Test 3: Modern libraries
echo "========================================"
echo "Test 3: Modern Libraries"
echo "========================================"
singularity exec --nv $BIND_MOUNTS "$CONTAINER_IMAGE" python -c "
import polars as pl
import mlflow
import optuna
import transformers
import accelerate
from hydra import compose, initialize

print(f'Polars version: {pl.__version__}')
print(f'MLflow version: {mlflow.__version__}')
print(f'Optuna version: {optuna.__version__}')
print(f'Transformers version: {transformers.__version__}')
print(f'Accelerate version: {accelerate.__version__}')
print('Hydra: OK')
print('All modern libraries imported successfully!')
"
echo ""

# Test 4: Run comprehensive test script
echo "========================================"
echo "Test 4: Comprehensive ML Test"
echo "========================================"
if [ -f "$TEST_SCRIPT" ]; then
    singularity exec --nv $BIND_MOUNTS "$CONTAINER_IMAGE" python "$TEST_SCRIPT"
else
    echo "Warning: Test script not found: $TEST_SCRIPT"
fi
echo ""

# Test 5: Distributed computing test
echo "========================================"
echo "Test 5: Distributed Computing"
echo "========================================"
singularity exec --nv $BIND_MOUNTS "$CONTAINER_IMAGE" python -c "
import torch.distributed as dist
from dask.distributed import Client, LocalCluster
import ray

# Test Dask
print('Testing Dask...')
cluster = LocalCluster(n_workers=2, threads_per_worker=2, processes=False)
client = Client(cluster)
print(f'Dask cluster: {client}')
client.close()
cluster.close()
print('Dask: OK')

# Test Ray
print('Testing Ray...')
ray.init(num_cpus=2, ignore_reinit_error=True)
print(f'Ray cluster resources: {ray.cluster_resources()}')
ray.shutdown()
print('Ray: OK')

print('Distributed computing tests passed!')
"
echo ""

echo "========================================"
echo "All tests completed successfully!"
echo "========================================"
echo "Container is ready for production use"
echo "Job finished at: $(date)"
