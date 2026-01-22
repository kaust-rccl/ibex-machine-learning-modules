#!/bin/bash
#SBATCH --time=08:00:00
#SBATCH --gpus-per-node=v100:1
#SBATCH --cpus-per-gpu=6
#SBATCH --mem=32G
#SBATCH --partition=batch
#SBATCH --job-name=ml-training-example
#SBATCH --mail-type=ALL
#SBATCH --output=logs/%x-%j-slurm.out
#SBATCH --error=logs/%x-%j-slurm.err

# ==============================================================================
# Example SLURM Job Script for ML Module Container
# ==============================================================================
# This script demonstrates how to use the ML Module container for training
# a machine learning model on the Ibex HPC cluster.
# ==============================================================================

set -e

echo "=========================================="
echo "ML Training Job with Singularity Container"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $(hostname)"
echo "Date: $(date)"
echo "GPUs allocated: $SLURM_GPUS_ON_NODE"
echo "CPUs allocated: $SLURM_CPUS_PER_TASK"
echo "Memory allocated: $SLURM_MEM_PER_NODE MB"
echo ""

# ==============================================================================
# Configuration
# ==============================================================================

# Container location (update this path after deployment)
CONTAINER="/ibex/shared/modules/machine-learning/1.0/ml_module.sif"
# Or use local container during testing:
# CONTAINER="$PWD/ml_module_v1.0.sif"

# Project directories
PROJECT_DIR="$PWD"
DATA_DIR="/ibex/user/$USER/data"
OUTPUT_DIR="/ibex/user/$USER/results/${SLURM_JOB_NAME}-${SLURM_JOB_ID}"
LOG_DIR="$OUTPUT_DIR/logs"

# Create output directories
mkdir -p "$OUTPUT_DIR"
mkdir -p "$LOG_DIR"

# Training script and parameters
TRAINING_SCRIPT="$PROJECT_DIR/examples/train_model.py"
MODEL_CONFIG="$PROJECT_DIR/configs/model_config.yaml"

# ==============================================================================
# Environment Setup
# ==============================================================================

# Bind mounts for the container
BIND_MOUNTS="--bind $PROJECT_DIR:/work"
BIND_MOUNTS="$BIND_MOUNTS --bind $DATA_DIR:/data:ro"  # Read-only data
BIND_MOUNTS="$BIND_MOUNTS --bind $OUTPUT_DIR:/output"
BIND_MOUNTS="$BIND_MOUNTS --bind $SLURM_TMPDIR:/tmp"

# Environment variables to pass to container
export PYTHONUNBUFFERED=1
export CUDA_VISIBLE_DEVICES=0  # Use first GPU
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

# MLflow tracking (optional)
export MLFLOW_TRACKING_URI="file://$OUTPUT_DIR/mlruns"
export MLFLOW_EXPERIMENT_NAME="my-experiment"

# Weights & Biases (optional - load from secrets)
if [ -f "$HOME/.secrets/wandb" ]; then
    source "$HOME/.secrets/wandb"
fi

echo "Container: $CONTAINER"
echo "Bind mounts: $BIND_MOUNTS"
echo "Output directory: $OUTPUT_DIR"
echo ""

# ==============================================================================
# Verify Container and GPU
# ==============================================================================

echo "=========================================="
echo "Verifying Container and GPU Access"
echo "=========================================="

# Check container exists
if [ ! -f "$CONTAINER" ]; then
    echo "ERROR: Container not found: $CONTAINER"
    exit 1
fi

# Display GPU information
singularity exec --nv $BIND_MOUNTS "$CONTAINER" nvidia-smi

# Verify frameworks can access GPU
singularity exec --nv $BIND_MOUNTS "$CONTAINER" python -c "
import torch
import tensorflow as tf
print(f'\nPyTorch CUDA available: {torch.cuda.is_available()}')
print(f'PyTorch GPU count: {torch.cuda.device_count()}')
print(f'TensorFlow GPU count: {len(tf.config.list_physical_devices(\"GPU\"))}')
"

echo ""

# ==============================================================================
# Run Training
# ==============================================================================

echo "=========================================="
echo "Starting Training Job"
echo "=========================================="
echo "Script: $TRAINING_SCRIPT"
echo "Config: $MODEL_CONFIG"
echo ""

# Run the training script inside the container
singularity exec --nv $BIND_MOUNTS "$CONTAINER" python "$TRAINING_SCRIPT" \
    --config "$MODEL_CONFIG" \
    --data-dir /data \
    --output-dir /output \
    --batch-size 64 \
    --epochs 100 \
    --learning-rate 0.001 \
    --num-workers $SLURM_CPUS_PER_TASK \
    --gpu 0 \
    --seed 42 \
    --log-dir /output/logs \
    --checkpoint-dir /output/checkpoints \
    --save-every 10

TRAINING_EXIT_CODE=$?

echo ""
echo "=========================================="
if [ $TRAINING_EXIT_CODE -eq 0 ]; then
    echo "Training completed successfully!"
else
    echo "Training failed with exit code: $TRAINING_EXIT_CODE"
fi
echo "=========================================="
echo ""

# ==============================================================================
# Post-processing (optional)
# ==============================================================================

if [ $TRAINING_EXIT_CODE -eq 0 ]; then
    echo "Running post-processing..."
    
    # Evaluate model
    singularity exec --nv $BIND_MOUNTS "$CONTAINER" python "$PROJECT_DIR/evaluate.py" \
        --checkpoint /output/checkpoints/best_model.pth \
        --data-dir /data/test \
        --output-file /output/evaluation_results.json
    
    # Generate visualizations
    singularity exec --nv $BIND_MOUNTS "$CONTAINER" python "$PROJECT_DIR/visualize.py" \
        --results /output/evaluation_results.json \
        --output-dir /output/figures
    
    echo "Post-processing completed"
fi

# ==============================================================================
# Cleanup and Summary
# ==============================================================================

echo ""
echo "=========================================="
echo "Job Summary"
echo "=========================================="
echo "Job ID: $SLURM_JOB_ID"
echo "Exit code: $TRAINING_EXIT_CODE"
echo "Output directory: $OUTPUT_DIR"
echo "Logs: $LOG_DIR"
echo "End time: $(date)"
echo ""

# List output files
echo "Generated files:"
ls -lh "$OUTPUT_DIR"

exit $TRAINING_EXIT_CODE
